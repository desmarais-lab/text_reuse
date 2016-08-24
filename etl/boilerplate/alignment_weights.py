from __future__ import unicode_literals, division, print_function
import sys
import io
import json
from pprint import pprint
from multiprocessing import Pool


def add_to_hm(hm, obj):
    if obj in hm:
        hm[obj] += 1
    else:
        hm[obj] = 1
    return(hm)

def matches_only(left_text, right_text):

    out = []
    for left, right in zip(left_text, right_text):
        if left == right:
            out.append(left)
        else:
            continue
    if out == '':
        print(left_text)
        print(right_text)
    out = ' '.join(out)
    return(out)


def generate_csv_line(line):

    doc = json.loads(line) 
    alignments = doc['alignments']

    if alignments is None:
        return None

    for alignment in alignments:

        # Get unique alignment
        left_text = alignment['left']
        right_text = alignment['right']

        ualign = matches_only(left_text, right_text)

        # Look up its score in the hashmap
        count = unique_alignments[ualign]

        score = alignment['score']
        adj_score = score * 1/count

        line_template ='{left_doc_id},{right_doc_id},{score},{adj_score},{alignment}\n'
        out_line = line_template.format(
                left_doc_id=doc['left_bill'],
                right_doc_id=doc['right_bill'],
                score=score,
                adj_score=adj_score,
                alignment=ualign
                )

        with io.open(OUTFILE, 'a', encoding='utf-8') as outfile:
            outfile.write(out_line)

        return out_line

if __name__ == "__main__":

    # Set Parameters
    INFILE = '../../data/alignments_new/ncsl_pair_alignments.json'
    #OUTFILE = '../../data/ncsl/ncsl_alignment_scores.csv'
    OUTFILE = 'ncsl_alignment_scores.csv'
    n_thread = 12

    
    # Generate a hashmap of counts of unique alignmetns
    unique_alignments = {}
    c = 0

    with io.open(INFILE, 'r', encoding='utf-8') as infile:

        for i,line in enumerate(infile):
            
            doc = json.loads(line)
            alignments = doc['alignments']

            if alignments is None:
                continue
            
            for alignment in alignments:

                left_text = alignment['left']
                right_text = alignment['right']

                if len(left_text) != len(right_text):
                    raise ValueError('Alignment Lengths differ')

                out = matches_only(left_text, right_text)
                unique_alignments = add_to_hm(unique_alignments, out)
                c += 1

            if i % 1000 == 0:
                print(i)

    print(len(unique_alignments))
    print(c)
    

    # Generate a csv file with scores and adjusted scores

    # Set up thread pool
    pool = Pool(n_thread) 
    
    # Set up csv output file
    header = 'left_doc_id,right_doc_id,score,adj_score\n'
    with io.open(OUTFILE, 'w', encoding='utf-8') as outfile:
        outfile.write(header)

    with io.open(INFILE, 'r', encoding='utf-8') as infile:

        pool.map_async(generate_csv_line, infile).get(99999)

        
