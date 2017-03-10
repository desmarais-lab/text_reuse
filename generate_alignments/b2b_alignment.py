from elasticsearch import Elasticsearch as ES
from text_cleaning import clean_document
from pprint import pprint
from time import time, sleep
from urllib3.exceptions import NewConnectionError
from socket import gaierror
from local_aligner import align, TimeOutError
import sys
import csv
import os
import numpy as np
import timeout_decorator

def get_bill_document(doc):
    last = doc.get("bill_document_last", None)
    first = doc.get("bill_document_first", None)

    if last is not None:
        return last
    elif first is not None:
        return first
    else:
        return None

def similar_doc_query(es_connection, text, state_id, num_results):
    """
     Query db for similar documents within documents of not the same state
    """
    
    # Elastic search query:
    query = {
        "query": {
            "bool": {
                "must": [
                    {
                        "more_like_this": {
                            "fields": ["bill_document_last.shingles"],
                            "like_text": text,
                            "max_query_terms": 25,
                            "min_term_freq": 1,
                            "min_doc_freq": 2,
                            "minimum_should_match": 1
                        }
                    },
                    {
                        "bool": { "must_not": { "match": {
                                    "state": state_id
                                }
                            }
                        }
                    }
                ]
            }
        }
    }

    results = es_connection.search(index="state_bills", body=query,
                                   size=num_results)

    max_score = results['hits']['max_score']
    results = results['hits']['hits']
    result_docs = []
    for res in results:
        doc = {}
        doc["bill_document_last"] = res["_source"]["bill_document_last"]
        doc["state"] = res["_source"]["state"]
        doc["score"] = res["_score"]
        doc["id"] = res["_id"]
        result_docs.append(doc)

    return result_docs, max_score

def write_outputs(alignments, bill_id, status, time, n_bills, 
                  output_dir, query_time, bill_length):
    
    alignment_file = os.path.join(output_dir, 'alignments/', 
                                  bill_id + '_alignments.csv')
    status_file = os.path.join(output_dir, 'bill_status/', 
                               bill_id + '_status.csv')

    with open(alignment_file, 'w', encoding='utf-8') as af,\
            open(status_file, 'w', encoding='utf-8') as sf:

        swriter = csv.writer(sf, delimiter=',', quotechar='"', 
                             quoting=csv.QUOTE_MINIMAL)
        swriter.writerow([bill_id, status, round(time, 4), n_bills,
                          query_time, bill_length])
        
        if len(alignments) > 0:
            awriter = csv.writer(af, delimiter=',', quotechar='"', 
                                 quoting=csv.QUOTE_MINIMAL)
     
            for a in alignments:
                awriter.writerow(a)


class NoConnectionError(Exception):
    pass

class NoTextError(Exception):
    pass

class NoBillError(Exception):
    pass

class TooLongError(Exception):
    pass


@timeout_decorator.timeout(3600, timeout_exception=TimeOutError)
def get_bill_alignments(BILL_ID, N_RIGHT_BILLS, MATCH_SCORE, MISMATCH_SCORE, 
                        GAP_SCORE, OUTPUT_DIR, ES_IP):
    
    global alignments
    global bill_length
    global n_right_bills
    global query_time

    # Establish elastic search connection
    es = ES(ES_IP, timeout=60, retry_on_timeout=True, max_retries=15)

    if not es.ping():
        raise NoConnectionError() from None

    # Get text of the left bill
    query_doc = es.get_source(index="state_bills", id=BILL_ID, 
                           doc_type="_all")

    if query_doc is None:
        raise NoBillError() 


    # Get most similar right bills
    query_text = get_bill_document(query_doc)
    if query_text is None:
        raise NoTextError()

    bill_length = len(query_text)
    if bill_length > 300000:
        raise TooLongError()

    query_text = clean_document(query_text, state_id=BILL_ID[:2])
    query_start = time()
    res, max_score = similar_doc_query(es_connection=es, text=query_text, 
                                       state_id=BILL_ID[:2], 
                                       num_results=N_RIGHT_BILLS)
    query_time = round(time() - query_start, 4)
    
    n_right_bills = len(res)
            
    # Align them
    for right_bill in res:
        
        bd = get_bill_document(right_bill)
        right_text = clean_document(bd,
                                    state_id=right_bill["state"])
        if len(right_text) > 300000:
            continue

        s = time()
        try:
            alignment = align(left=query_text, right=right_text, 
                              match=MATCH_SCORE, gap=GAP_SCORE,
                              mismatch=MISMATCH_SCORE)
        except TimeOutError:
            alignment = [None, None, None] 
        at = time() - s

        alignment.insert(0, right_bill["id"])
        alignment.insert(0, BILL_ID)
        alignment.extend([round(right_bill["score"], 4), 
                          round(max_score, 4), round(at, 4)])

        alignments.append(alignment)

    print("Sucessfully terminated")

    return alignments, n_right_bills, query_time, bill_length

if __name__ == "__main__":

    # =========================================================================
    # Config
    # =========================================================================
    BILL_ID = sys.argv[1]
    
    N_RIGHT_BILLS = int(sys.argv[2])
    MATCH = int(sys.argv[3])
    MISMATCH = int(sys.argv[4])
    GAP = int(sys.argv[5])
    OUTPUT_DIR = sys.argv[6]
    ES_IP = sys.argv[7]
    # =========================================================================

    status = "successfull"
    start_time = time()
    n_right_bills = None
    query_time = None
    bill_length = None
    alignments = []
    
   
    try:
        get_bill_alignments(BILL_ID, N_RIGHT_BILLS, MATCH, MISMATCH, GAP, 
                            OUTPUT_DIR, ES_IP)

    # Handle exceptions
    except NoConnectionError:
        status = "connection_error"
        raise

    except NoTextError:
        status = "no_text"
        raise

    except NoBillError:
        status = "no_bill"
        raise
    
    except TimeOutError:
        status = "bill_timeout"
        raise

    except TooLongError:
        status = "skipped_for_length"
        raise

    except:
        status = "other_error"
        raise

    finally:
        elapsed_time = time() - start_time 
        write_outputs(alignments, BILL_ID, status, elapsed_time, n_right_bills,
                      OUTPUT_DIR, query_time, bill_length)


