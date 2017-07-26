import sys
import csv
import os
import itertools
import multiprocessing
import time

import numpy as np
import pandas as pd

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
    
    if (left_doc is None or right_doc is None
        or (len(left_doc) + len(right_doc)) > 5e5):
        return None
    
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
    bill_ids = pd.read_csv('../data/ncsl/ncsl_data_from_sample_matched.csv')

    # Get all combinations within parent topics
    combos = []
    grouped = bill_ids.groupby('parent_topic')
    for name, data in grouped:
        c = itertools.combinations(data['matched_from_db'], 2)
        combos.extend(list(c))

    with open(OUTF, 'w', encoding='utf-8') as outfile:
        
        start = time.time()
        pool = multiprocessing.Pool(processes=N_PROC) 
        results = pool.map(align_pair, combos)
        pool.close()
        print(time.time() - start)
        
        # Write output
        writer = csv.writer(outfile, delimiter=',', quotechar='"', 
                            quoting=csv.QUOTE_MINIMAL)
        header = ['left_id', 'right_id', 'score', 'left_alignment_text',
                  'right_alignment_text']
        writer.writerow(header)

        for r in results:
            if r is None:
                continue
            writer.writerow(r)
