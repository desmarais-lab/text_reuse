# Generate a csv with metadata on all bills. 
# Calculates average ideology of all bill sponsors (from malp data)

from __future__ import unicode_literals, print_function

import json
import io
from pprint import pprint
import pandas as pd
import numpy as np
import time
import re

BILL_FILE = '../data/extracted_bills_with_sponsers.json'
OUTFILE = '../data/bill_metadata.csv'
N_SPON = 3

legislators = pd.read_csv('../data/legislators.csv')
header = ['unique_id', 'date_introduced', 'date_signed', 'date_last_action', 
          'date_passed_upper', 'date_passed_lower', 'state', 'chamber', 
          'bill_type', 'short_title', 'session', 'bill_title', 
          'sponsor_idology', 'num_sponsors']
header = ','.join(header)
# Get a set of all legislators that we have ideology for
known_legis = set(legislators['id'])

# Regex to remove chars that mess up the csv
re_nchar = re.compile(r'[,"\']')


with io.open(BILL_FILE, 'r', encoding='utf-8') as infile,\
        io.open(OUTFILE, 'w+', encoding='utf-8') as outfile:
    
    counter = 0
    outfile.write(header + '\n')
    for i, line in enumerate(infile):
        
        doc = json.loads(line)

        # Print progress
        if i % 1000 == 0:
            print(i)

        # Some documents failed to extract, skip corresponding lines        
        if doc is None:
            continue

        # Extract info from the bill json object
        l = len(doc['sponsers'])

        # Take quote characters out of string fields
        if doc['short_title'] is not None:
            doc['short_title'] = re_nchar.sub('', doc['short_title'])
        if doc['bill_title'] is not None:
            doc['bill_title'] = re_nchar.sub('', doc['bill_title'])
        
        row = [doc['unique_id'], doc['date_introduced'], doc['date_signed'],
               doc['action_dates']['last'], doc['action_dates']['passed_upper'],
               doc['action_dates']['passed_lower'], doc['state'], doc['chamber'],
               doc['bill_type'][0], doc['short_title'], doc['session'], 
               doc['bill_title']
               ]
    
        # Calculate the average ideology
        sponsors = [d['leg_id'] for d in doc['sponsers']]
        scores = []
        for sponsor in sponsors:
            if sponsor not in known_legis:
                continue
            else:
                score = legislators.ideology[legislators['id'] == sponsor].tolist()
            scores.extend(score)
      
        if len(scores) > 0:
            score = np.mean(scores)
        else:
            score = None

        # Append average score and number of sponsors to df-row
        row.append(score)
        row.append(l)
        row_str = ['"{}"'.format(el) for el in row]
        out_line = ','.join(row_str) + '\n'
        
        # Write to file
        outfile.write(out_line)
        counter += 1
