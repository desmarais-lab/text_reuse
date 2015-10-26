from __future__ import division, unicode_literals, print_function
from pprint import pprint
from elasticsearch import Elasticsearch
import json
import io

# CONFIG
OUTFILE = '../data/lid/all_bills_metadata.csv'
ELASTICIP = '54.244.236.175'
ELASTICPORT = '9200'
IDFILE = '../data/lid/bill_ids.txt'
LIMIT = 10

outfile = io.open(OUTFILE, 'w+', encoding='utf-8')
idfile = io.open(IDFILE, 'r', encoding='utf-8')

for index, id_ in idfile:
    



id_file.close()
outfile.close() 
