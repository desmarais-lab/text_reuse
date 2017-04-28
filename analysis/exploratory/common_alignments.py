import csv
import sys
import operator
import pickle

sys.path.append('../../generate_alignments/')
from process_alignments import matches_only



if __name__ == "__main__":

    ALIGNMENT_FILE = '../../data/aligner_output/alignments.csv'

    all_alignments = {}
    with open(ALIGNMENT_FILE, 'r') as infile:
        reader = csv.reader(infile, delimiter=',', quotechar='"')
        header = next(reader)
        print(header)
        for i,row in enumerate(reader):
            text = ' '.join(matches_only(row[3], row[4]))
            all_alignments[text] = all_alignments.get(text, 0) + 1
            if i % 10**6 == 0:
                print(i)

    sorted_x = sorted(all_alignments.items(), key=operator.itemgetter(1),
                      reverse = True)
    print(sorted_x[:10])
    pickle.dump(all_alignments, open('all_alignments.p', 'wb'))
    
