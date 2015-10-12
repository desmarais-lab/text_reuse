# Extract only bill ids and alignment scores (remove the alignment text from the
# alignment dataset)
import csv
import sys

# Increase maximum csv field size (very long alignments)
csv.field_size_limit(sys.maxsize)


with open('bill_to_bill_alignments.csv', 'r') as infile, open('alignment_scores_only.csv', 'a') as outfile:

    reader = csv.reader(infile, delimiter = ',', quotechar = '"')
    writer = csv.writer(outfile, delimiter = ',', quotechar = '"')
    header = ['left_doc_i', 'right_doc_i', 'alignment_score']
    #writer.writerow(header)
    
    errors = 0
    for index, row in enumerate(reader):
        out_row = [row[0], row[1], row[4]]
        writer.writerow(out_row)
        if index % 100000 == 0:
            print 'Done with {} of 7930050'.format(index)
