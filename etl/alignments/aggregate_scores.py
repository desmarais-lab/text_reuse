# Aggregate alignment scores in csv format to state- and bill-dyad level
from __future__ import unicode_literals, print_function
import io
from pprint import pprint
import sys
import itertools
import math

# Input: Section to secdtion alignent scores in csv format
INFILE = '../../data/alignments_new/adjusted_scores.csv'

# Bill to bill output excluding within state alignments
B2B_FILE = '../../data/alignments_new/bill2bill_scores.csv'

# State to state output
S2SFILE = '../../data/alignments_new/state2state_scores.csv'

# Abbreviations file
ABBRFILE = 'state_abbreviations.txt'

# Generate all state to state combinations
with io.open(ABBRFILE, 'r') as infile:
    abbr = [e.strip('\n').lower() for e in infile.readlines()]

dyads = ['_'.join(sorted(list(e))) for e in itertools.combinations(abbr, 2)]

for s in abbr:
    dyads.append('{}_{}'.format(s,s))
dyads = set(dyads)

# open files
infile = io.open(INFILE, 'r')
b2b_file = io.open(B2B_FILE, 'w', encoding='utf-8')

l0 = None
r0 = None

# Write b2b header
b2b_file.write('left_doc_id,right_doc_id,alignment_score\n')

# State dict
state_dyads = {}

for i,line in enumerate(infile):
    # Skip header
    if i == 0: 
        continue
     
    fields = line.strip('\n').split(',')

    l = fields[0]
    r = fields[1]
    
    # Add the score to the state dyad
    states = [l[0:2], r[0:2]]
    states.sort() 
    state_dyad = "_".join(states)

    if state_dyad not in state_dyads:
        state_dyads[state_dyad] = {'sum_score': float(fields[3]),
                                   'n_align': 0}
    else:
        state_dyads[state_dyad]['sum_score'] += float(fields[3])
        state_dyads[state_dyad]['n_align'] += 1

    
    # New bill dyad
    if r != r0 and r0 is not None: 
        # Write last dyad's score to file
        outline = '{},{},{}\n'.format(l0, r0, score)
        b2b_file.write(outline)
        score = float(fields[3])
        l0 = l
        r0 = r
    # Same bill dyad
    elif r0 is not None:
        score += float(fields[3])
    # First line
    else:
        score = float(fields[3])
        l0 = l
        r0 = r
 
    if i % 1000000 == 0:
        print(i)

with io.open(S2SFILE, 'w', encoding='utf-8') as s2sfile:
    s2sfile.write('left_state,right_state,sum_score,n_alignments\n')

    for d in state_dyads:
        doc = state_dyads[d]
        outline ='{},{},{},{}\n'.format(d[0:2],d[3:5],
                                           doc['sum_score'],
                                           doc['n_align'])
        s2sfile.write(outline) 

infile.close()
b2b_file.close()
