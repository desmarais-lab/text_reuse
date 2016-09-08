# Take the alignment score json file and generate a smaller file that contains
# just the bill ids and alignments


# This script will also correct for an early bug where alignments of the bill
# with itself have been calculated. This occured only for the first few thousand
# bills

from __future__ import unicode_literals
import io
import json
from pprint import pprint
import sys
from time import time


INFILE = '../../data/alignments_new/alignments_1000.json'
# File to store the alignment scores (section dyad level)
AS_OUTFILE = '../../data/alignments_new/alignments_1000.csv'
# File to store the lucene scores in (bill dyad level)
LS_OUTFILE = '../../data/alignments_new/lucene_scores_1000.csv'

with io.open(INFILE, 'r', encoding='utf-8') as infile,\
        io.open(AS_OUTFILE, 'w+', encoding='utf-8') as as_file,\
        io.open(LS_OUTFILE, 'w+', encoding='utf-8') as ls_file:

    # Write outfile headers
    header = 'left_doc_id,right_doc_id,{}\n'
    as_file.write(header.format('alignment_score'))
    ls_file.write(header.format('lucene_score'))
 
    # Loop over left bills
    s = time()
    for i, line in enumerate(infile):
        
        if len(line) < 500:
            continue
        
        try:
            doc = json.loads(line)
        except ValueError:
            print "json error in line {}".format(i)
            continue
        results = doc['alignment_results']
        left_id = doc['query_document_id']
        
        # Loop over right bills
        for res in results:
            
            right_id = res['document_id']
            # Weed out alignments of the bill with itself
            if right_id == left_id:
                continue
            ls = res['lucene_score']        
            ls_line = '{},{},{}\n'.format(left_id,right_id,ls)
            ls_file.write(ls_line)
 
            alignments = res['alignments']
            # Loop over section pairs (allignments between these bills)
            for j,alignment in enumerate(alignments):

                # Extract all relevant info from alignment doc
                try:
                    score = alignment['score']
                except KeyError:
                    print "Key error in line {}. No score key for alignment {}".format(i,j)
                    continue

                # Make the csv line
                out_line = '{},{},{}\n'.format(left_id,right_id,score)
                as_file.write(out_line)
            
        if i % 10000 == 0:
            print "{}: This batch: {}s".format(i, time() - s)
            s = time()
