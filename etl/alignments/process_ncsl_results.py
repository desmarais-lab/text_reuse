from __future__ import unicode_literals, division, print_function
import sys
import io
import json
from pprint import pprint
from multiprocessing import Pool
import numpy as np
import re
import operator
import Stemmer
import time
import cPickle as pickle
from gensim import corpora, matutils
import scipy.sparse as sps
from sklearn.metrics.pairwise import cosine_similarity
import os
import re
import subprocess
from process_alignment_results import AlignmentMatchText 
from alignment_weights import calc_similarities


if __name__ == "__main__":

    start = time.time()

    # Set parameters
    ## Files
    FULL_ALIG_FILE = '../../data/alignments_new/ncsl_pair_alignments.json'
    ALIG_SCORE_FILE = '../../data/alignments_new/ncsl_pair_alignments.csv'
    ALIG_TEXT_FILE = '../../data/alignments_new/ncsl_align_text.csv' 
    ADJ_SCORE_FILE = '../../data/alignments_new/ncsl_adjusted.csv'
    
    ## Options
    remove_same_state = False
    
    # Make a list of the alignments and collect the vocabulary
    # Remove same state alignments (if set to true)
    # Generate the alignment score csv
    # Generate the lucene score csv
    
    print('Initializing stemmer and iterator...')   
    stemmer = Stemmer.Stemmer('english').stemWord
    alignments = AlignmentMatchText(FULL_ALIG_FILE, stemmer, remove_same_state,
                                    type="ncsl")

    print('Creating dictionary and output files...')
    with io.open(ALIG_TEXT_FILE, 'w', encoding='utf-8') as align_file,\
            io.open(ALIG_SCORE_FILE, 'w', encoding='utf-8') as align_score_file:
        
        out_line = '{left_doc_id},{right_doc_id},{entry}\n'

        # Write headers
        align_file.write(out_line.format(left_doc_id='left_doc_id',
                                              right_doc_id='righ_doc_id', 
                                              entry='match_text')) 
        align_score_file.write(out_line.format(left_doc_id='left_doc_id',
                                               right_doc_id='righ_doc_id',
                                               entry='alignment_score'))
        for n_align,a in enumerate(alignments):
            # Write alignment score and match text
            align_file.write(out_line.format(left_doc_id=a['left_id'],
                                             right_doc_id=a['right_id'],
                                             entry=a['text']))
            

            # Alignment score
            align_score_file.write(out_line.format(left_doc_id=a['left_id'],
                                                   right_doc_id=a['right_id'],
                                                   entry=a['ascore']))

    # Get indices for random samples
    n = 1000
    np.random.seed(3468934)
    sample_1 = set(np.random.choice(alignments.size,size=n,replace=False))
    sample_2 = set(np.random.choice(alignments.size,size=n,replace=False))

    # Store the dictionary
    alignments.dictionary.save("../../data/alignments_new/ncsl_dictionary.dict")
    
    # Pass through the data and generate bow representations of the 2 samples
    print('Generating random samples...')
    with io.open(ALIG_TEXT_FILE, 'r', encoding='utf-8') as text_file:

        # bow arrays
        samp1_bow = []
        samp2_bow = []

        # array counter
        s1 = 0
        s2 = 0
                
        for idx, line in enumerate(text_file):

            # Skip header
            if idx == 0:
                continue
            # Select line if it is in one of the samples
            if idx in sample_1:
                cells = line.split(',')
                text = cells[2].split()
                tokens = alignments._proc_text(text)
                samp1_bow.append(alignments.dictionary.doc2bow(tokens))
                s1 += 1

            if idx in sample_2:
                cells = line.split(',')
                text = cells[2].split()
                tokens = alignments._proc_text(text)
                samp2_bow.append(alignments.dictionary.doc2bow(tokens))
                s2 += 1
    
        # Transform to sparse doc-term-matrix (first 1000 rows are samp1)
        samps = samp1_bow + samp2_bow
        data = []
        rows = []
        cols = []
        for i, doc in enumerate(samps):
            for x in doc:
                data.append(x[1])
                cols.append(x[0])
                rows.append(i)
        compmat = sps.csr_matrix((data, (rows, cols)), 
                shape=(len(samps), len(alignments.dictionary)))
        
        # Pickle the compmat and the alignmetns obj
        pickle.dump(compmat, open("ncsl_compmat.p", "wb"))

    print('Calculating weights...')
    # Pass through the data again and calculate cosine similarities between each 
    # alignment text and each row of the 2 vectors

    with io.open(ALIG_TEXT_FILE, 'r', encoding='utf-8') as text_file,\
            io.open(ALIG_SCORE_FILE, 'r') as score_file,\
            io.open(ADJ_SCORE_FILE, 'w', encoding='utf-8') as outfile:

        outline = '{left},{right},{score}\n'

        # Write header
        outfile.write(outline.format(left='left_doc_id',
                                     right='right_doc_id',
                                     score='alignment_score'))

        for i, (tline, sline) in enumerate(zip(text_file, score_file)):
            # Skip header
            if i == 0:
                continue
            l, r, w1, w2 = calc_similarities(inline=tline, comparison=compmat,
                                            n=n, align=alignments,
                                            dictionary=alignments.dictionary)
            oscore = sline.strip('\n').split(',')[2]
            wscore = float(oscore) * (1 - float(w1))
            outfile.write(outline.format(left=l, right=r, score=wscore))
