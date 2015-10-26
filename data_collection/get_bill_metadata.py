from __future__ import division, print_function, unicode_literals
from elasticsearch import Elasticsearch
import json
import io
import time
from pprint import pprint
import warnings

# CONFIG
# ============================================================================== 
OUTFILE = '../data/lid/all_bills_metadata.csv'
ELASTICIP = '54.244.236.175'
ELASTICPORT = 9200
IDFILE = '../data/lid/bill_ids.txt'
LIMIT = 2000
FIELDS = ['bill_id', 'unique_id', 'short_title',  'bill_type', 'date_created', 'date_introduced', 
        'date_signed', 'session', 'state']
BATCHSIZE = 1000
# ==============================================================================

def write_batch(results, outfile):
    for result in results:
        cells = [0] * len(FIELDS)
        for i, field in enumerate(FIELDS):

            try:
                cell = result['fields'][field] 
            except KeyError:
                cell = 'NA'
            if cell is None:
                cell = 'NA'
            elif isinstance(cell, list) and len(cell) == 1:
                cell = cell[0]
            elif isinstance(cell, list) and len(cell) > 1:
                msg = 'Warning: Multiple entries in field. Bill: {0}, field: {1}'.format(result['_id'], field)
                warnings.warn(msg)
            elif isinstance(cell, str) or isinstance(cell, unicode):
                pass
            else:
                msg = 'Unexpected field type. Bill: {0}, field: {1}'.format(result['_id'], field)
                raise ValueError(msg)

            cells[i] = cell
        row = ','.join(cells) + '\n'
        outfile.write(row)

if __name__ == '__main__':

    outfile = io.open(OUTFILE, 'w+', encoding='utf-8')
    idfile = io.open(IDFILE, 'r', encoding='utf-8')

    ec = Elasticsearch([{'host': ELASTICIP, 'port': ELASTICPORT}])

    # Write csv header
    header = ','.join(FIELDS) + '\n'
    outfile.write(header)

    # Get metadata in bulk in batches of BATCHSIZE
    ids = []
    b = 1
    for index, id_ in enumerate(idfile):

        if index > LIMIT:
            break
        id_ = id_.strip('\n')
        ids.append({'_id': id_})
        if index % 1000 == 0 and index != 0:   
            bulk_result = ec.mget(body={'docs': ids}, index='state_bills', 
                                  doc_type='bill_document', fields=FIELDS)        
            ids = []
            write_batch(bulk_result['docs'], outfile)
            print('\rProcessed batch {0}'.format(b), end="")
            b += 1 

    print('\n')
        
    idfile.close()
    outfile.close() 
