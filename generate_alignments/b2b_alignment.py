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
                            "max_query_terms": 15,
                            "min_term_freq": 3,
                            "min_doc_freq": 5,
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
                                   filter_path=['hits.hits._id', 
                                                'hits.hits.state',
                                                'hits.hits.bill_document_last',
                                                'hits.hits.bill_document_first'],
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

def write_outputs(alignments, bill_id, status, time, n_bills, n_success, 
                  output_dir):
    
    alignment_file = os.path.join(output_dir, 'alignments/', 
                                  bill_id + '_alignments.csv')
    status_file = os.path.join(output_dir, 'bill_status/', 
                               bill_id + '_status.csv')

    with open(alignment_file, 'w', encoding='utf-8') as af,\
            open(status_file, 'w', encoding='utf-8') as sf:

        swriter = csv.writer(sf, delimiter=',', quotechar='"', 
                             quoting=csv.QUOTE_MINIMAL)
        swriter.writerow([bill_id, status, round(time, 4), n_bills, n_success])
        
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


def get_bill_alignments(BILL_ID, N_RIGHT_BILLS, MATCH_SCORE, MISMATCH_SCORE, 
                        GAP_SCORE, OUTPUT_DIR, ES_IP):
    
    sleep(np.random.exponential(1))
    alignments = []
    status = "successfull"
    start_time = time()
    n_right_bills = None
    n_success = 0

    try:
        # Establish elastic search connection
        es = ES(ES_IP, timeout=5, retry_on_timeout=True, max_retries=10)

        if not es.ping():
            raise NoConnectionError() from None

        # Get text of the left bill
        query_doc = es.get_source(index="state_bills", id=BILL_ID, 
                               doc_type="_all")

        if query_doc is None:
            raise NoBillError() 

        # Get most similar right bills
        if query_doc["bill_document_last"] is not None:
            query_text = query_doc["bill_document_last"]
        elif query_doc["bill_document_first"] is not None:
            query_text = query_doc["bill_document_first"]
        else:
            raise NoTextError()

        query_text = clean_document(query_text, state_id=BILL_ID[:2])
        res, max_score = similar_doc_query(es_connection=es, text=query_text, 
                                           state_id=BILL_ID[:2], 
                                           num_results=N_RIGHT_BILLS)
        
        
        print('Success in {}'.format(time() - start_time))
        return None

        n_right_bills = len(res)
                
        # Align them
        for right_bill in res:

            right_text = clean_document(right_bill["bill_document_last"],
                                        state_id=right_bill["state"])
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
            n_success += 1

        print("Sucessfully terminated")

    # Handle exceptions
    except NoConnectionError:
        status = "connection_error"

    except NoTextError:
        status = "no_text"

    except NoBillError:
        status = "no_bill"

    except:
        status = "other_error"

    finally:
        elapsed_time = time() - start_time 
        write_outputs(alignments, BILL_ID, status, elapsed_time, n_right_bills,
                      n_success, OUTPUT_DIR)

    return status

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
    
    get_bill_alignments(BILL_ID, N_RIGHT_BILLS, MATCH, MISMATCH, GAP, OUTPUT_DIR, 
                        ES_IP)
