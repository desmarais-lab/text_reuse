import io
import json
import re
import sys


def get_alignment_text(left_bill, right_bill, alignment_file):

    out = []
    with io.open(alignment_file) as infile:
        
        out = []
        for i,line in enumerate(infile):

            if left_bill in line and right_bill in line:
                out.append(line )

            if i % 1000000 == 0:
                print i

    for l in out:
        print l
if __name__ == "__main__":

    alignment_file = sys.argv[1]
    left_bill = sys.argv[2]
    right_bill = sys.argv[3]

    get_alignment_text(left_bill, right_bill, alignment_file)
