# Aggregate alignment scores in csv format to state- and bill-dyad level
from __future__ import unicode_literals
import io
from pprint import pprint

# Input: Section to secdtion alignent scores in csv format
INFILE = '../../data/alignments_new/alignments_1000.csv'
# Bill-to bill output
B2BFILE = '../../data/lid/alignments_1000_b2b.csv'
# State to state output
S2SFILE = '../../data/lid/alignments_1000_s2s.csv'


infile = io.open(INFILE, 'r')
b2bfile = io.open(B2BFILE, 'w', encoding='utf-8')

l0 = None
r0 = None

# Write b2b header
b2bfile.write('left_doc_id,right_doc_id,alignment_score\n')

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
        state_dyads[state_dyad] = {'sum_score': float(fields[2]),
                                   'n_align': 0}
    else:
        state_dyads[state_dyad]['sum_score'] += float(fields[2])
        state_dyads[state_dyad]['n_align'] += 1

    # New bill dyad
    if r != r0: 
        # Write last dyad's score to file
        try:
            outline = '{},{},{}\n'.format(l0, r0, score)
            b2bfile.write(outline)

        # First line no score from last entry
        except NameError:
            pass
        score = float(fields[2])
        l0 = l
        r0 = r
    # Same bill dyad
    else:
        score += float(fields[2])

    if i % 100000 == 0:
        print i

with io.open(S2SFILE, 'w', encoding='utf-8') as s2sfile:
    s2sfile.write('left_state,right_state,sum_score,n_alignments\n')

    for d in state_dyads:
        doc = state_dyads[d]
        outline ='{},{},{},{}\n'.format(d[0:2],d[3:5],
                                        doc['sum_score'],
                                        doc['n_align'])
        s2sfile.write(outline) 

infile.close()
b2bfile.close()
