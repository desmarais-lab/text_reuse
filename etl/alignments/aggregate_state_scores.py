# Aggregate alignment scores in csv format to state- and bill-dyad level
from __future__ import unicode_literals, print_function
import io
from pprint import pprint
import sys
import itertools
import math

# Input: Section to secdtion alignent scores in csv format
INFILE = '../../data/alignments_new/adjusted_scores.csv'

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
