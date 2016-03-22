# Take the alignment score json file and generate a smaller file that contains
# just the bill ids and alignments


# This script will also correct for an early bug where alignments of the bill
# with itself have been calculated. This occured only for the firs few thousand
# bills

from __future__ import unicode_literals
import io
import json
from pprint import pprint


INFILE = '../data/alignments_new/alignments_1000_sample.json'
OUTFILE = '../data/alignments_new/alignments_1000_sample.csv'

with io.open(INFILE) as infile, io.open(OUTFILE, 'w+', encoding='utf-8') as outfile:


    # Write outfile header
    header = 'left_doc_id,right_doc_id,alignment_score\n'
    outfile.write(header)
    
    # Loop over left bills
    for i, line in enumerate(infile):
        
        if len(line) < 500:
            continue

        doc = json.loads(line)
        results = doc['alignment_results']
        left_id = doc['query_document_id']
        
        # Loop over right bills
        for res in results:
            
            right_id = res['document_id']

            # Weed out alignments of the bill with itself
            if right_id == left_id:
                continue
            
            alignments = res['alignments']
            # Loop over section pairs (allignments between these bills)
            for alignment in alignments:

                # Extract all relevant info from alignment doc
                score = alignment['score']
                #left_span = '{}_{}'.format(alignment['left_start'],
                #                           alignment['left_end'])
                #right_span = '{}_{}'.format(alignment['right_start'],
                #                            alignment['right_end'])

                # Make the csv line
                out_line = '{},{},{}\n'.format(left_id,right_id,score)
                outfile.write(out_line)



                



