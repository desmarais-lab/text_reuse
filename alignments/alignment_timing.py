from __future__ import unicode_literals, print_function
import sys
from pprint import pprint
import numpy as np
import io
from elasticsearch import Elasticsearch
import json
import time
import copy

sys.path.append('../../../policy_diffusion/lid/')
from text_alignment import LocalAligner, AffineLocalAligner
from database import ElasticConnection
from utils.text_cleaning import clean_document
from utils.general_utils import alignment_tokenizer

# Select 1000 random bills
np.random.seed(234234)
n_bills = 1200 # 10% bills are empty so I choose a higher number
random_lines = np.random.choice(a=565970, size=n_bills, replace=False).tolist()
random_lines.sort()
j = 0
bill_ids = []
with open('../../data/lid/bill_ids.txt', 'r') as id_file:
    for i, line in enumerate(id_file):
        if i == random_lines[j]:
            bill_ids.append({'_id': line.strip('\n')})
            j += 1
            if j == n_bills:
                break
        else:
            continue

# Get them from the database

ec = Elasticsearch([{'host': '54.244.236.175', 'port': 9200}])
results = ec.mget(body={'docs': bill_ids}, index='state_bills', 
                  doc_type='bill_document', fields=['bill_document_last'])

# Extract relevant info and clean text
bills = []
no_text = []
for result in results['docs']:
    try:
        doc = {}
        doc['id_'] = result['_id']
        doc['state'] = result['_id'].split('_')[0]
        text = result['fields']['bill_document_last'][0]
        doc['text'] = clean_document(text, doc_type='state_bill',
                                     state_id=doc['state'], )
        doc['tokenized'] = [alignment_tokenizer(s) for s in doc['text']]
        doc['size'] = len(doc['tokenized'])
        bills.append(doc)
    except KeyError as e:
        no_text.append(result['_id'])
        continue
       
 
aligner = AffineLocalAligner()
outfile = io.open('../../data/lid/alignment_timing.csv', 'w+', encoding='utf-8')
outfile.write('focus_bill,right_bill,score,time,alignment_length,left_bill_length, right_bill_lenght\n')
alignment_file = io.open('../../data/lid/alignment_text.csv', 'w+', encoding='utf-8')
alignment_file.write('left_bill_text, right_bill_text\n')

i = 0
pairs = [] 
right_bills = copy.copy(bills)

for j, focus_bill in enumerate(bills):
        
    # Remove focus bill from comparison bills
    right_bills.pop(j)

    for right_bill in right_bills:
        s = time.time()
        alignment_obj = aligner.align(focus_bill['tokenized'], right_bill['tokenized'])
        res = alignment_obj[0]
        row = '{},{},{},{},{},{},{}\n'.format(focus_bill['id_'], 
                                        right_bill['id_'], 
                                        res['score'], 
                                        time.time() - s,
                                        len(res['left']),
                                        len(focus_bill['tokenized'][0]),
                                        len(right_bill['tokenized'][0])
                                        )
        outfile.write(row)
        alignment_file.write('{},{}\n'.format(' '.join(res['left']), ' '.join(res['right'])))
        i += 1
        if i % 1000 == 0:
            print('Done with {}'.format(i))
        
outfile.close()
alignment_file.close()
