from __future__ import unicode_literals, print_function, division
import cPickle as pickle
import io
import sys
import re
import time
from process_alignment_results import AlignmentMatchText
import Stemmer
import scipy.sparse as sps
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
import os


def calc_similarities(inline, comparison, n, dictionary):
    '''
    Calculate the cosines similarity between an alignment and the
    other sampled alignments

    text: str, line of the input csv file
    comparision: scipy.csc_matrix, comparison docs
    n: size of each comparison set
    dictionary: gensim dictionary for the corpus
    '''

    # Preprocess input alignment
    left_doc_id, right_doc_id, text = line.split(',')
    text = text.strip('\n')
    tokens = alignments._proc_text(text.split())
    bow = dictionary.doc2bow(tokens)

    # Generate sparse vector
    data = [x[1] for x in bow]
    rows = [0] * len(bow)
    cols = [x[0] for x in bow] 
    sparse = sps.csr_matrix((data, (rows, cols)), 
            shape=(1, len(dictionary)))

    score = cosine_similarity(sparse, compmat).squeeze()
    score1 = np.round(score[:n].mean(), decimals=4)
    score2 = np.round(score[n:].mean(), decimals=4)

    return left_doc_id, right_doc_id, score1, score2

if __name__ == "__main__":

    INFILE = sys.argv[1]
    JOB_ID = re.sub('[^0-9]', '', os.path.basename(INFILE))

    OUTFILE = '/storage/home/fjl128/scratch/text_reuse/adjusted_alignments_{}.csv'.format(JOB_ID)
    #OUTFILE = 'temp/adjusted_alignments_{}.csv'.format(JOB_ID)
    CMFILE = 'compmat.p'
    DICTFILE = 'dictionary.p'
    with io.open(DICTFILE, 'rb') as infile:
        dicti = pickle.load(infile)
    with io.open(CMFILE, 'rb') as infile:
        compmat = pickle.load(infile)

    outline = '{left_doc_id},{right_doc_id},{weight_1},{weight_2}\n'
    
    stemmer = Stemmer.Stemmer('english').stemWord
    alignments = AlignmentMatchText('xyz', stemmer=stemmer,
            remove_same_state=True)

    with io.open(OUTFILE, 'w', encoding='utf-8') as outfile,\
            io.open(INFILE, 'r', encoding='utf-8') as infile:

        # write header
        outfile.write(outline.format(left_doc_id='left_doc_id',
                                     right_doc_id='right_doc_id',
                                     score_1='score_1',
                                     score_2='score_2'))

        for line in infile:
            out = calc_similarities(inline=line, comparison=compmat, n=1000,
                    dictionary=dicti)
            outfile.write(outline.format(left_doc_id=out[0],
                                         right_doc_id=out[1],
                                         score_1=out[2],
                                         score_2=out[3]))
