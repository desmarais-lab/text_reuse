# Calculate alignments and lucene scores for sample of bills

from __future__ import unicode_literals, print_function
import sys
from pprint import pprint
import numpy as np
import io
from elasticsearch import Elasticsearch
import json
import time
import copy
import multiprocessing as mp

sys.path.append('../../../policy_diffusion/lid/')
from text_alignment import LocalAligner, AffineLocalAligner
from database import ElasticConnection
from utils.text_cleaning import clean_document
from utils.general_utils import alignment_tokenizer
from lid import LID

# ==========================================================================
# Config
# --------------------------------------------------------------------------

N_FOCUS_BILLS = 1000
N_RIGHT_BILLS = 1000

PROCESSES = 40

META_FILE = '../../data/lid/lu_al_score_metadata.csv'
TEXT_FILE = '../../data/lid/lu_al_score_text.txt'

# ==========================================================================

# Total timer
start = time.time()

# Select 1000 random bills
np.random.seed(234234)
random_lines = np.random.choice(a=565970, size=N_FOCUS_BILLS, replace=False).tolist()
random_lines.sort()
j = 0
bill_ids = []
with open('../../data/lid/bill_ids.txt', 'r') as id_file:
    for i, line in enumerate(id_file):
        if i == random_lines[j]:
            bill_ids.append({'_id': line.strip('\n')})
            j += 1
            if j == N_FOCUS_BILLS:
                break
        else:
            continue

# Get them from the database
print("Getting Focus bills from DB...")
ec = Elasticsearch([{'host': '54.244.236.175', 'port': 9200}])
results = ec.mget(body={'docs': bill_ids}, index='state_bills', 
                  doc_type='bill_document', fields=['bill_document_last'])

# Extract relevant info and clean text
print("Extracting info...")
bills = []
for result in results['docs']:
    doc = {}
    doc['id_'] = result['_id']
    doc['state'] = result['_id'].split('_')[0]
    try:
        doc['text'] = result['fields']['bill_document_last'][0] 
        bills.append(doc)
    except KeyError:
        pass

lid = LID(elastic_host='54.244.236.175', query_results_limit=N_RIGHT_BILLS, 
          lucene_score_threshold=float('-Inf'))

print("Calculating Alignments...")
def get_alignments(bill):
    elastic_query = ' '.join(bill['text'])
    alignment_docs = lid.find_state_bill_alignments(
        query_document=bill['text'],
        state_id=bill['state'],
        query_document_id=bill['id_'],
        split_sections=True,
        query_result_limit=N_RIGHT_BILLS
        )
    print("Done with {}".format(bill['id_']))
    return alignment_docs


# Create multiprocessing pool
pool = mp.Pool(processes=PROCESSES)
results = pool.map(get_alignments, bills)

print('Writing output to disk...')
with io.open(META_FILE, 'w+', encoding='utf-8') as meta, \
        io.open(TEXT_FILE, 'w+', encoding='utf-8') as text:


    # Write headers
    meta_header = ('focus_bill_id,right_bill_id,focus_bill_length,'
                   'right_bill_length,alignment_score,lucene_score,'
                   'query_time,align_time\n')
    meta.write(meta_header)
    text.write('focus_text,right_text\n')

    # Loop over focus bills
    bc = 0
    lr = len(results)
    for result in results:
        focus_id = result['query_document_id'] 
        query_time = result['query_time']
        focus_length = result['query_doc_length']

        # Loop over right documents        
        for right_doc in result['alignment_results']:
            right_id = right_doc['document_id']
            right_length = right_doc['doc_length']
            lucene_score = right_doc['lucene_score']
            align_time = right_doc['alignment_time']
           
            # Loop over sections
            for alignment in right_doc['alignments']:
                score = alignment['score']
                focus_text = ' '.join(alignment['left'])
                right_text = ' '.join(alignment['right'])
                
                # Generate rows
                meta_row = '{},{},{},{},{},{},{},{}\n'.format(
                        focus_id,
                        right_id,
                        focus_length,
                        right_length,
                        score,
                        lucene_score,
                        query_time,
                        align_time
                        ) 
                text_row = '{},{}\n'.format(focus_text,right_text)

                # Write rows
                meta.write(meta_row)
                text.write(text_row)
        bc += 1
        print("\rDone with {} of {}".format(bc, lr), end="")

    print('\n')

print('Completed in {} seconds'.format(time.time() - start))
