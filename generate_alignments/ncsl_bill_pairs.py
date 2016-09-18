#!/opt/anaconda/bin/python 
from __future__ import unicode_literals
import sys 
sys.path.append('../policy_diffusion/lid/')
from lid import LID
from text_alignment import AffineLocalAligner,LocalAligner
from utils.text_cleaning import clean_document 
import database
import json
import base64
import codecs
import re
import logging
import os
import traceback
import sys
from utils.general_utils import deadline,TimedOutExc
from database import ElasticConnection
import time
import io
import itertools
from pprint import pprint
import numpy as np
import sys
import multiprocessing
from functools import partial

# TODO: dedicated I/O process for result output. There have been some conflicts
# (very few though)

def align_pair(c, split):
    '''
    c: tuple, (left_bill, right_bill)
    split: bool, should bills be split in sections
    '''
    s = time.time()
    alignments = lidy.align_bill_pair(right_doc_id=c[0], 
                                      left_doc_id=c[1],
                                      split_sections=split)
    out = {'left_bill': c[0], 
           'right_bill': c[1], 
           'alignments':alignments}
    
    #with io.open(outfile_name, 'a', encoding='utf-8') as outfile:
    #    outfile.write(unicode(json.dumps(out)) + '\n')
    print(time.time() - s) 

    return out


if __name__ == '__main__':

    # Parameters

    # Number of processes
    n_proc = 40
     
    OUTF = '../data/alignments_new/ncsl_pair_alignments_nosplit.json'
    #OUTF = 'ncsl_pair_alignments.json'

    SPLIT=False
     
    # Initialize aligner
    aligner = AffineLocalAligner(match_score=4, mismatch_score=-1, gap_start=-3, 
                                 gap_extend = -1.5)

    # Initialize LID
    ES_IP = "54.244.236.175"
    lidy = LID(query_results_limit=1000, elastic_host=ES_IP, 
               lucene_score_threshold=0, aligner=aligner)

    # Load list of bills
    with io.open('../data/ncsl/matched_ncsl_bill_ids.txt') as infile:
        bill_ids = [s.strip('\n') for s in infile.readlines()]

    # Get all combinations
    c = itertools.combinations(bill_ids, 2)
    
    combos = [x for x in c]

    part_align_pair = partial(align_pair, split=SPLIT)

    pool = multiprocessing.Pool(processes=n_proc) 
    results = pool.map_async(part_align_pair, combos).get(9999999)
    
    # Write output
    with io.open(OUTF, 'w', encoding='utf-8') as outfile:
        for r in results:
            outfile.write(unicode(json.dumps(r)) + '\n')
