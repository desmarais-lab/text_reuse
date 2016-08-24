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


def align_pair(c):
    '''
    c: tuple, (left_bill, right_bill)
    '''
    alignments = lidy.align_bill_pair(c[0], c[1])
    out = {'left_bill': c[0], 
           'right_bill': c[1], 
           'alignments':alignments}
    #with io.open(outfile_name, 'a', encoding='utf-8') as outfile:
    #    outfile.write(unicode(json.dumps(out)) + '\n')

    print(json.dumps(out) + '\n')
 
    return None


if __name__ == '__main__':

    # Parameters
    ## Set to false and specify last pair if picking up old calculation
    scratch = True

    # Number of processes
    n_proc = 40
     
    #outfile_name = '../data/alignments_new/ncsl_pair_alignments.json'
    #outfile_name = 'ncsl_pair_alignments.json'

    # Set up logging
    logging.basicConfig(level=logging.DEBUG)
    logging.getLogger('elasticsearch').setLevel(logging.ERROR)
    logging.getLogger('urllib3').setLevel(logging.ERROR)
    logging.getLogger('json').setLevel(logging.ERROR)
             
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
    
    if scratch:
        #with io.open(outfile_name, 'w', encoding='utf-8') as outfile:
        #    outfile.write('')

        combos = [x for x in c]
    else:
        last = ('sc_2015-2016_H3682','wa_2015-2016_HB1092')

        combos = []
        for i,x in enumerate(c):           
            if x != last:
                continue
            else:
                combos.append(x)

    l_temp = '{},{},{}\n'

    pool = multiprocessing.Pool(processes=n_proc)
    results = pool.map_async(align_pair, combos).get(9999999)
