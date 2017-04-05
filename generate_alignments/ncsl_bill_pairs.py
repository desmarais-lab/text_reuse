import sys
import csv
import os
import itertools
import multiprocessing

import numpy as np

from elasticsearch import Elasticsearch as ES
from text_cleaning import clean_document
from local_aligner import align, TimeOutError
from b2b_alignment import get_bill_document


def align_pair(pair):
    '''
    pair: tuple, (left_bill, right_bill)
    '''
    # Get bill text
    left_source = es.get_source(index="state_bills", id=pair[0], 
                                doc_type="_all") 
    right_source = es.get_source(index="state_bills", id=pair[1], 
                                 doc_type="_all")

    left_doc = get_bill_document(left_source)
    right_doc = get_bill_document(right_source)
    
    if (left_doc is None or right_doc is None or
        len(left_doc) > 3e5 or len(right_doc) > 3e5):
        return [None] * 3
    
    left_doc = clean_document(left_doc, state_id=left_source["state"])
    right_doc = clean_document(right_doc, state_id=right_source["state"])
        
    try:
        alignment = align(left_doc, right_doc, 3, -3, -2)
    except TimeOutError:
        alignment = [None] * 3

    alignment.insert(0, pair[1])
    alignment.insert(0, pair[0])

    return alignment


if __name__ == '__main__':

    # Config
    N_PROC = 10
    OUTF = '../data/aligner_output/ncsl_alignments.csv'
     
    # DB connection
    es = ES("localhost:9200", timeout=60, retry_on_timeout=True, max_retries=15)

    # Load list of bills
    with open('../data/ncsl/matched_ncsl_bill_ids.txt') as infile:
        bill_ids = [s.strip('\n') for s in infile.readlines()]

    # Get all combinations
    c = itertools.combinations(bill_ids, 2)
    
    combos = [x for x in c]

    with open(OUTF, 'w', encoding='utf-8') as outfile:

        pool = multiprocessing.Pool(processes=N_PROC) 
        results = pool.imap(align_pair, combos, chunksize=1000)
        pool.close()
        
        # Write output
        writer = csv.writer(outfile, delimiter=',', quotechar='"', 
                            quoting=csv.QUOTE_MINIMAL)
        header = ['left_id', 'right_id', 'score', 'left_alignment_text',
                  'right_alignment_text']
        writer.writerow(header)

        for r in results:
            writer.writerow(r)
