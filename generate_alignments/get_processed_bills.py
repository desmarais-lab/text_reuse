from __future__ import unicode_literals
import sys
import io
import glob
import json
import os
import re

RESULT_FILE = '../data/alignments_new/alignments_1000.json'
#result_files = glob.glob(os.path.join(RESULT_DIR, 'alignments_1000*'))

outfile = io.open('processed_bills.txt', 'w+', encoding='utf=8')
reg = re.compile(r',.+')


with io.open(RESULT_FILE) as infile:

    for i,line in enumerate(infile):

        if i % 100 == 0:
            print i
         
        line = reg.sub('}', line)

        try:
            doc = json.loads(line)
        except ValueError:
            print "json error in line {}".format(i)
            continue
        
        try:
            id_ = doc['query_document_id']
        except KeyError:
            print "no id in line {}".format(i)
            
        
        outfile.write(id_)
        outfile.write('\n')
        

outfile.close()
