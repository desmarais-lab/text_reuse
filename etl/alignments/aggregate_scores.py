# Aggregate alignment scores in csv format to state- and bill-dyad level
from __future__ import unicode_literals
import io
from pprint import pprint
import sys
import itertools
import math

# Input: Section to secdtion alignent scores in csv format
INFILE = '../../data/alignments_new/alignments_1000.csv'
# Bill-to bill output
B2B_LOG_FILE = '../../data/lid/alignments_1000_b2b.csv'
# Bill to bill output excluding within state alignments
B2B_AS_FILE = '../../data/lid/alignments_1000_b2b_ns.csv'

# State to state output
S2SFILE = '../../data/lid/alignments_1000_s2s.csv'
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
b2b_log_file = io.open(B2B_LOG_FILE, 'w', encoding='utf-8')
b2b_as_file = io.open(B2B_AS_FILE, 'w', encoding='utf-8')

l0 = None
r0 = None

# Write b2b header
b2b_as_file.write('left_doc_id,right_doc_id,alignment_score\n')
b2b_log_file.write('left_doc_id,right_doc_id,alignment_score\n')

# State dict
state_dyads = {}
last_states = [None, None]

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

    if state_dyad not in dyads:
        print state_dyad
        continue

    if state_dyad not in state_dyads:
        state_dyads[state_dyad] = {'sum_score': float(fields[2]),
                                   'sum_log_score': math.log(float(fields[2])),
                                   'n_align': 0}
    else:
        state_dyads[state_dyad]['sum_score'] += float(fields[2])
        try:
            state_dyads[state_dyad]['sum_log_score'] += math.log(float(fields[2]))
        except ValueError:
            continue

        state_dyads[state_dyad]['n_align'] += 1

    # New bill dyad
    if r != r0: 
        # Write last dyad's score to file
        try:
            outline = '{},{},{}\n'.format(l0, r0, log_score)
            b2b_log_file.write(outline)

            # Only write if not same state dyad
            if not last_states[0] == last_states[1]:
                b2b_as_file.write(outline)

        # First line no score from last entry
        except NameError:
            pass

        log_score = math.log(float(fields[2]))
        l0 = l
        r0 = r
    # Same bill dyad
    else:
        log_score += math.log(float(fields[2]))

    if i % 1000000 == 0:
        print i

    last_states = states

with io.open(S2SFILE, 'w', encoding='utf-8') as s2sfile:
    s2sfile.write('left_state,right_state,sum_score,sum_log_score,n_alignments\n')

    for d in state_dyads:
        doc = state_dyads[d]
        outline ='{},{},{},{},{}\n'.format(d[0:2],d[3:5],
                                           doc['sum_score'],
                                           doc['sum_log_score'],
                                           doc['n_align'])
        s2sfile.write(outline) 

infile.close()
b2b_as_file.close()
b2b_log_file.close()
