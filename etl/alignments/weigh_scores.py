from __future__ import unicode_literals, print_function, division
import io
import sys
import glob
import os
import re
from pprint import pprint
import time


if __name__ == "__main__":

    OFILE = '../../data/alignments_new/alignments_1000.csv'
    SFILE = '../../data/alignments_new/adjusted_scores.csv'
    CDIR = '/storage/home/fjl128/scratch/text_reuse/adjusted*.csv'
    N_CHUNKS = 80
    
    # Get the filenames (have to be sorted in the same order as before,
    # to match the alignments in the alignment file)
    cfiles = sorted(glob.glob(CDIR), 
                    key=lambda x: int(re.sub('[^0-9]', '', 
                                             os.path.basename(x))))

    # Generate file handles
    handles = [io.open(f, 'r') for f in cfiles]
    
   
    with io.open(SFILE, 'w', encoding='utf-8') as outfile,\
            io.open(OFILE, 'r', encoding='utf-8') as infile:

        # Prepare output file
        out_line = '{left},{right},{ascore},{score_1},{score_2}\n'
        header = out_line.format(left='left_doc_id',
                                 right='right_doc_id',
                                 ascore='alignment_score',
                                 score_1='score_1',
                                 score_2='score_2')
        outfile.write(header)

        start = time.time()
        for idx,oline in enumerate(infile):
            # Skip headers
            if idx == 0:
                print(idx)
                for f in handles:
                    next(f)
                continue

            oleft, oright, oscore = oline.split(',')
            oscore = float(oscore)

            j = idx % N_CHUNKS
            nfile = handles[j]
            wline = next(nfile)
            wleft, wright, w1, w2 = wline.split(',')
           
            # Check if files are still aligned
            if idx % 1000000 == 0:
                t = time.time() - start 
                print('Iteration: {}. Time: {}'.format(idx, t))
                start = time.time()
                if oright != wright:
                    raise ValueError('Files not aligned.')
            
            # Calculate the weighted scores
            s1 = float(oscore) * (1 - float(w1))
            s2 = float(oscore) * (1 - float(w2))

            # Write output
            outfile.write(out_line.format(left=oleft,
                                          right=oright,
                                          ascore=oscore,
                                          score_1=s1,
                                          score_2=s2))

     

