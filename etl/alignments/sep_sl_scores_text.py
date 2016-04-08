# Split up the bill to bill alignment score data set to have a smaller dataset
# without the alignment text

from __future__ import unicode_literals
import io
import time

infile = io.open('../../data/lid/bill_to_bill_alignments.csv', 'r', encoding = 'utf-8')
outfile = io.open('../../data/lid/bill_to_bill_scores_only.csv', 'w+', encoding = 'utf-8')

outfile.write('left_doc_id,right_doc_id,alignment_score\n')
for i,line in enumerate(infile):
    els = line.split(',')
    new_line = '{},{},{}\n'.format(els[0], els[1], els[-2])
    outfile.write(new_line)
    if i % 10000 == 0:
        print i

infile.close()
outfile.close()
