# Reads in the openstates legislators database, and matches it to the 
# MALP data set

from __future__ import unicode_literals, print_function

import json
import pandas as pd
import os
from pprint import pprint
import time
import sys
import numpy as np
import hashlib


# Load the MALP file
malppath = '../data/malp/malp_individual.tab'
malp = pd.read_csv(malppath, sep='\t', low_memory=False, encoding='utf-8')

# Create first and last name columns
firsts = []
lasts = []
for name in malp.name:
    splt = name.split(',')
    lasts.append(splt[0])
    try:
        firsts.append(splt[1].split()[0])
    except IndexError:
        firsts.append('')

# Append to malp data frame
malp['first_name'] = firsts
malp['last_name'] = lasts
malp.st = [x.lower() for x in malp.st.tolist()]
malp_small = pd.DataFrame(malp[['first_name', 'last_name', 'party', 'st', 'np_score']])
malp_small.columns = ['first_name', 'last_name', 'party', 'state', 'ideology']


def get_value(doc, key, na_value=None):
    '''
    Return 'NA' if key does not exist in dictionary
    '''
    try:
        return doc[key]
    except KeyError:
        return na_value

def party_label(label):
    if label == 'Republican':
        return 'R'
    elif label in ['Democratic', 'Democratic-Farmer-Labor']:
        return 'D'
    elif label is None:
        return None
    else:
        return 'I'
       
# Loop through all the sunlight files and make data frame
i = 0
duplicate = 0
cols = ['id', 'first_name', 'last_name', 'party', 'state']
df = pd.DataFrame(columns = cols)
#m = hashlib.md5()
datapath = '../data/lid/legislators'

for (dirpath, dirnames, filenames) in os.walk(datapath):
    
    for c_file in filenames:
        
        path = os.path.join(dirpath, c_file)
        doc = json.loads(open(path, 'r').read())
        row = [get_value(doc, k) for k in cols]
        
        # See if party is somewhere in old_roles
        if row[3] is None:
            for key in doc['old_roles'].keys():
                for item in doc['old_roles'][key]:
                    if 'party' in item.keys():
                        row[3] = item['party']
                    else:
                        pass

            
        # Clean first name
        if row[1] is not None and row[1] != '':
            row[1] = row[1].split()[0].capitalize()
        else:
            row[1] = None
        
        # Check for duplicates
        #if row[1] is not None and row[2] and row[3] is not None and row[4] is not None:
        #    s = row[1] + row[2] + row[3] + row[4]
        #    hash_id = hashlib.md5(s.encode('utf-8')).hexdigest()
        #    if hash_id in ids:
        #        duplicate += 1

        #    ids.add(hash_id)
        #    row.append(hash_id)
        #else:
        #    row.append(None)
        #    pass
        
        # Uniform party labels
        row[3] = party_label(row[3])
        
        # Add row to the df
        df.loc[i] = row
        
        # Bookkeeping
        i += 1
        if i % 100 == 0:
            print('\r{}'.format(i), end = "")


# Join the dataframes
joined = pd.merge(malp_small, df, on=['first_name', 'last_name', 'party', 'state'])

# Write to 
joined.to_csv('../data/legislators.csv')

