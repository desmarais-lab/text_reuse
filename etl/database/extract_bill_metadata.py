# Generate a csv with metadata on all bills. 
# Calculates average ideology of all bill sponsors (from malp data)
import json
from pprint import pprint
import pandas as pd
import numpy as np
import time
import re
import csv


def has_bill_text(b):
    if b["bill_document_last"] is None and b["bill_document_first"] is None:
        return False
    else:
        return True

def get_bill_document(doc):
    last = doc.get("bill_document_last", None)
    first = doc.get("bill_document_first", None)

    if last is not None:
        return last
    elif first is not None:
        return first
    else:
        return None

def party_to_int(party_str):
    if party_str == 'R':
        return 1
    elif party_str == 'D':
        return 0
    else:
        return np.nan


if __name__ == "__main__":
    
    # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Config
    # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    BILL_FILE = '../../data/initial_data/extracted_bills_with_sponsers.json'
    OUTFILE = '../../data/bill_metadata.csv'
    BILL_ID_FILE = '../../data/bill_ids.txt'
    N_SPON = 3
    # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    legislators = pd.read_csv('../../data/initial_data/legislators.csv')

    header = ['unique_id', 'date_introduced', 'date_signed', 'date_last_action', 
              'date_passed_upper', 'date_passed_lower', 'state', 'chamber', 
              'bill_type', 'short_title', 'session', 'bill_title', 'bill_length',
              'sponsor_idology', 'num_sponsors', 'primary_sponsor_party', 
              'variance_sponsors_party']

    # Get a set of all legislators that we have ideology for
    known_legis = set(legislators['id'])

    with open(BILL_FILE, 'r', encoding='utf-8') as infile,\
         open(OUTFILE, 'w+', encoding='utf-8') as outfile,\
         open(BILL_ID_FILE, 'w', encoding='utf-8') as idfile:
        
        writer = csv.writer(outfile, delimiter=',', quotechar='"',
                            quoting=csv.QUOTE_MINIMAL)
        writer.writerow(header)

        for i, line in enumerate(infile):

            if i % 1000 == 0:
                print(i)

            if line == "null\n":
                continue

            doc = json.loads(line)

            if not has_bill_text(doc):
                continue
            
            # Write the bill id to file
            idfile.write(doc['unique_id'] + '\n')

            bill_text = get_bill_document(doc)
            bill_length = len(bill_text.split())

            row = [doc['unique_id'], doc['date_introduced'], doc['date_signed'],
                   doc['action_dates']['last'], 
                   doc['action_dates']['passed_upper'],
                   doc['action_dates']['passed_lower'], 
                   doc['state'], doc['chamber'], doc['bill_type'][0], 
                   doc['short_title'], doc['session'], doc['bill_title'], 
                   bill_length]
             
            # Calculate the average ideology
            sponsors = [d['leg_id'] for d 
                        in doc['sponsers'] if d['type'] == 'primary']
            l = len(sponsors)
            scores = []
            parties = []
            for sponsor in sponsors:
                if sponsor not in known_legis:
                    continue
                else:
                    score = (legislators.ideology[legislators['id'] == sponsor]
                                        .tolist())
                    party = (legislators.party[legislators['id'] == sponsor]
                                        .tolist())
                scores.extend(score)
                parties.extend(party)
            
            if len(scores) > 0:
                score = np.mean(scores)
            else:
                score = np.nan
            if len(parties) > 0:
                primary_party = parties[0]
                party_variance = np.nanvar([party_to_int(x) for x in parties])
            else:
                primary_party = np.nan
                party_variance = np.nan

            # Append average score and number of sponsors to df-row
            row.append(score)
            row.append(l)
            row.append(primary_party)
            row.append(party_variance)
            writer.writerow(row)
