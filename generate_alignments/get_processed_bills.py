from __future__ import unicode_literals
import sys
import io
import glob
import json
import os
import re

RESULT_DIR = '../data/alignments_new'
result_files = glob.glob(os.path.join(RESULT_DIR, '*.json'))
print result_files
outfile = io.open('processed_bills.txt', 'w+', encoding='utf=8')
reg = re.compile(r',.+')

for j,f in enumerate(result_files):
    print f 

    with io.open(f) as infile:

        for i,line in enumerate(infile):

            if i % 100 == 0:
                print i
             
            line = reg.sub('}', line)

            try:
                doc = json.loads(line)
            except ValueError:
                print "json error in line {}".format(i)
                continue

            id_ = doc['query_document_id']
            
            outfile.write(id_)
            outfile.write('\n')
            

outfile.close()
