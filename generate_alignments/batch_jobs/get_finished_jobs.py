from __future__ import unicode_literals
import io
import sys
import os
import glob
import re
import json

def file_len(fname):
    with io.open(fname) as f:
        for i, l in enumerate(f):
            pass
    return i + 1

RESULT_DIR = '../data/alignments/'
files = glob.glob(os.path.join(RESULT_DIR, '*.json'))
with io.open('processed_bills.txt', 'w+') as outfile:
    outfile.write('')
with io.open('../data/alignments_new/alignments_batch_jobs.json', 'w+',
        encoding='utf-8') as resultfile:
    resultfile.write('')
 
re_nn = re.compile(r'[^0-9]') 

for f in files:
    print 'processing {}'.format(f)
    #f_path = os.path.join(RESULT_DIR, f)
    with io.open(f) as current_file:
            
        for line in current_file:

            doc = json.loads(line)

            if 'error' in doc:
                continue
            else:
                query_doc = doc['query_document_id']
                with io.open('processed_bills.txt', 'a') as outfile:
                    outfile.write(query_doc)
                    outfile.write('\n')
                with io.open('../data/alignments_new/alignments_batch_jobs.json', 'a',
                        encoding='utf-8') as resultfile:
                    resultfile.write(unicode(json.dumps(doc)))
                    resultfile.write('\n')
