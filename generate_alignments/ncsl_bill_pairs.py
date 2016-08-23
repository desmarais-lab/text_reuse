#!/opt/anaconda/bin/python 
from __future__ import unicode_literals
import sys 
sys.path.append('/storage/home/fjl128/bruce_shared/text_reuse/policy_diffusion/lid/')
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

    if alignments is None:
        l = l_temp.format(c[0], c[1], np.nan)
        with io.open(outfile_name, 'a', encoding='utf-8') as outfile:
            outfile.write(l)
        continue

    for alignment in alignments:
        pprint(alignment)
        sys.exit()
        score = alignment['score']
        l = l_temp.format(c[0], c[1], score)
        with io.open(outfile_name, 'a', encoding='utf-8') as outfile:
            outfile.write(l)


logging.basicConfig(level=logging.DEBUG)
logging.getLogger('elasticsearch').setLevel(logging.ERROR)
logging.getLogger('urllib3').setLevel(logging.ERROR)
logging.getLogger('json').setLevel(logging.ERROR)

outfile_name = '../data/alignments_new/ncsl_pair_alignments.csv'
         
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


combos = itertools.combinations(bill_ids, 2)

# Uncomment when not picking up bu starting from scratch
with io.open(outfile_name, 'w', encoding='utf-8') as outfile:
    l = 'left_bill,right_bill,score\n'
    outfile.write(l)

l_temp = '{},{},{}\n'

last = ('ma_187th_H4070','wa_2013-2014_SB5419')
start = True

# Loop through all combinations of bills
for i,c in enumerate(combos):

    if not start: 
        if c == last:
            start = True
        continue
    
    alignments = lidy.align_bill_pair(c[0], c[1])

    if alignments is None:
        l = l_temp.format(c[0], c[1], np.nan)
        with io.open(outfile_name, 'a', encoding='utf-8') as outfile:
            outfile.write(l)
        continue

    for alignment in alignments:
        pprint(alignment)
        sys.exit()
        score = alignment['score']
        l = l_temp.format(c[0], c[1], score)
        with io.open(outfile_name, 'a', encoding='utf-8') as outfile:
            outfile.write(l)
