from __future__ import unicode_literals
import io
import sys
import os
import glob
import re

def file_len(fname):
    with io.open(fname) as f:
        for i, l in enumerate(f):
            pass
    return i + 1

RESULT_DIR = '../data/alignments/'
files = glob.glob(os.path.join(RESULT_DIR, '*.json'))
outfile = io.open('completed_jobs.txt', 'w+')

re_nn = re.compile(r'[^0-9]') 

for f in files:
    #f_path = os.path.join(RESULT_DIR, f)
    if file_len(f) == 29:
	job_id = re_nn.sub('', f)
	outfile.write(job_id + '\n')


outfile.close()
	    
