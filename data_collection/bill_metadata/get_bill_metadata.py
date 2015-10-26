from __future__ import division, print_function, unicode_literals
from elasticsearch import Elasticsearch
import json
import io
import time
from pprint import pprint
import os

# CONFIG
# ============================================================================== 
IDFILE = '../../data/lid/bill_ids.txt'
OUTFILE = '../../data/lid/all_bills_metadata.csv' 
ELASTICIP = '54.244.236.175'
ELASTICPORT = 9200
SKIP = None 
LIMIT = None
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
                msg = 'Bill: {0}, field: {1}. Multiple entries: {2}. Using first entry'.format(result['_id'], field, cell)
                logfile.write(msg + '\n')
                cell = cell[0]
            elif isinstance(cell, str) or isinstance(cell, unicode):
                pass
            else:
                msg = 'Unexpected field type. Bill: {0}, field: {1}'.format(result['_id'], field)
                raise ValueError(msg)

            cells[i] = cell
        try:
            row = ','.join(cells) + '\n'
        except TypeError as e:
            pprint(cells) 
            raise TypeError(e)
        outfile.write(row)

if __name__ == '__main__':

    outfile = io.open(OUTFILE, 'w+', encoding='utf-8')
    idfile = io.open(IDFILE, 'r', encoding='utf-8')
    LOGFILE = os.path.basename(__file__) + '_log.txt'
    logfile = io.open(LOGFILE, 'w+', encoding='utf-8')

    ec = Elasticsearch([{'host': ELASTICIP, 'port': ELASTICPORT}])

    # Write csv header
    header = ','.join(FIELDS) + '\n'
    outfile.write(header)

    # Get metadata in bulk in batches of BATCHSIZE
    ids = []
    b = 1
    for index, id_ in enumerate(idfile):
        if SKIP is not None and index < SKIP:
            continue
        if LIMIT is not None and index > LIMIT:
            break
        id_ = id_.strip('\n')
        ids.append({'_id': id_})
        if index % 1000 == 0 and index != 0:   
            bulk_result = ec.mget(body={'docs': ids}, index='state_bills', 
                                  doc_type='bill_document', fields=FIELDS)        
            ids = []
            write_batch(bulk_result['docs'], outfile)
            print('Processed batch {0}'.format(b))
            b += 1 

    print('\n')
        
    idfile.close()
    outfile.close() 
    logfile.close()
