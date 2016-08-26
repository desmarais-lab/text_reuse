from __future__ import unicode_literals, division, print_function
import sys
import io
import json
from pprint import pprint
from multiprocessing import Pool
import numpy as np
import re
import operator

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
    out = ' '.join(out)
    return(out)


def generate_csv_line(line):
    
    line_template ='{left_doc_id},{right_doc_id},{score},{adj_score}\n'

    try:
        doc = json.loads(line) 
    except ValueError:
        return None

    alignments = doc['alignments']

    if alignments is None:
        out_line = line_template.format(
                left_doc_id=doc['left_bill'],
                right_doc_id=doc['right_bill'],
                score=np.nan,
                adj_score=np.nan
                )
        return None

    for alignment in alignments:

        # Get unique alignment
        left_text = alignment['left']
        right_text = alignment['right']

        ualign = matches_only(left_text, right_text)

        # Look up its score in the hashmap
        count = unique_alignments[ualign]

        score = alignment['score']
        adj_score = round(score * 1/count, 4)
        
        if ualign == 'means a letter':
            pprint(doc)

        out_line = line_template.format(
                left_doc_id=doc['left_bill'],
                right_doc_id=doc['right_bill'],
                score=score,
                adj_score=adj_score
                )

        with io.open(OUTFILE, 'a', encoding='utf-8') as outfile:
            outfile.write(out_line)

    return out_line

if __name__ == "__main__":

    # Set Parameters
    INFILE = '../../data/alignments_new/ncsl_pair_alignments.json'
    OUTFILE = '../../data/ncsl/ncsl_alignment_scores.csv'
    ALIGNFILE = '../../data/ncsl/unique_alignments.tsv'
    #OUTFILE = 'ncsl_alignment_scores.csv'
    n_thread = 12

    
    # Generate a hashmap of counts of unique alignmetns
    unique_alignments = {}
    c = 0

    with io.open(INFILE, 'r', encoding='utf-8') as infile:

        for i,line in enumerate(infile):
            

            try:
                doc = json.loads(line)
            except ValueError:
                print('Json decoder error in line {}. Skipping.'.format(i))
                continue 


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

            if i % 10000 == 0:
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

    
    # Write out the alignment dictionary
    out_line = '{count}\t{alignment}\n'

    ## Make list of tuples from dict
    sorted_ualign = sorted(unique_alignments.items(), key=operator.itemgetter(1))
    
    with io.open(ALIGNFILE, 'w', encoding='utf-8') as outfile:
        outfile.write('count\talignment\n')
        for t in sorted_ualign:
            ualign = t[0]
            count = t[1]
            text = re.sub('[^a-zA-Z0-9 ]', '', ualign)
            if text == '':
                text = '_'
            o = out_line.format(
                    alignment=text,
                    count=count)
            outfile.write(o)

