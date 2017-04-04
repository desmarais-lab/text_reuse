import re
import Stemmer
import os
import csv
import logging
import pickle
import sys

import numpy as np
import scipy.sparse as sps

from time import time
from gensim import corpora, matutils
from sklearn.metrics.pairwise import cosine_similarity

# Generate the reweigted scores

# - Split the alignment file into alignment text and score file
# - Take a sample of 1000 alignments (for comparison) and store 
#   as doc-term matrix


def matches_only(left_text, right_text):
    '''
    Return the matching tokens of two alignments
    '''
    out = []
    schar = re.compile('[^A-Za-z]')

    for left, right in zip(left_text.split(), right_text.split()):
        left = schar.sub('', left)
        right = schar.sub('', right)

        if left == right:
            out.append(left)

    return out

def proc_text(word_list, stemmer):

    out = [None] * len(word_list)
    for i,word in enumerate(word_list):
        out[i] = stemmer(word.lower())
    
    return out


def calc_similarities(text, comparison, dictionary, stemmer):
    '''
    Calculate the cosines similarity between an alignment and the
    other sampled alignments

    text: list, tokenized alignment text to be adjusted
    comparision: scipy.csc_matrix, comparison docs
    dictionary: gensim dictionary for the corpus
    align: AlignmentMatchText class
    '''

    # Preprocess input alignment
    tokens = proc_text(text, stemmer)
    bow = dictionary.doc2bow(tokens)

    # Generate sparse vector
    data = [x[1] for x in bow]
    rows = [0] * len(bow)
    cols = [x[0] for x in bow]
    sparse = sps.csr_matrix((data, (rows, cols)),
            shape=(1, len(dictionary)))

    comparison = comparison.transpose()
    scores = cosine_similarity(sparse, comparison).squeeze()
    score = np.round(scores.mean(), decimals=4)

    return score

if __name__ == "__main__":


    # Config
    DATA_DIR = '/storage/home/fjl128/scratch/text_reuse/data/aligner_output/'
    ALIGNMENT_OUTPUT = os.path.join(DATA_DIR, 'alignments.csv')
    
    SCORES = os.path.join(DATA_DIR, 'alignments_notext.csv')

    n = 1000 # size of comparison samples
    stemmer = Stemmer.Stemmer('english').stemWord 
    
    logging.basicConfig(level=logging.INFO)

    with open(ALIGNMENT_OUTPUT, 'r', encoding='utf-8') as infile,\
         open(SCORES, 'w') as scorefile:
        
        reader = csv.reader(infile, delimiter=',', quotechar='"')
        score_writer = csv.writer(scorefile, delimiter=',', quotechar='"',
                                  quoting=csv.QUOTE_MINIMAL)

        # Count total number of rows in data
        if not os.path.exists('n_alignments.p'):
            logging.info('Counting alignments...')
            m = sum([1 for row in reader])
            pickle.dump(m, open('n_alignments.p', 'wb'))
            infile.seek(0)
        else:
            m = pickle.load(open('n_alignments.p', 'rb'))
        
        logging.info(f'{m} alignments in {ALIGNMENT_OUTPUT}')
        # Next pass through the data. Generate dictionary and sample matrix

        if not os.path.exists('sample_indices.p'):
            np.random.seed(3468934)
            logging.info('Select sample alignments...')
            sample = set(np.random.choice(m, size=n, replace=False))
            pickle.dump(sample, open('sample_indices.p', 'wb'))
        else:
            sample = pickle.load(open('sample_indices.p', 'rb'))

        if (not os.path.exists('dictionary.p') or
           not os.path.exists('sample_tdm.p')):

            logging.info(('Making sample matrix and dictionary'))
            sample_bow = []
            dictionary = corpora.Dictionary()
            for i,row in enumerate(reader):

                # If selected for sample, process and append to sample corpus
                if i in sample:
                    matched_text = matches_only(row[3], row[4])
                    tokens = proc_text(matched_text, stemmer)
                    sample_bow.append(dictionary.doc2bow(tokens, 
                                                         allow_update=True))

                if i % 10**6 == 0:
                    perc = round((i / m) * 100, 2)
                    logging.info(f'{perc} percent done')

            
            sample_tdm = matutils.corpus2csc(sample_bow, 
                                             num_terms=len(dictionary), 
                                             num_docs=n)
            logging.info(f'Shape of sample matrix: {sample_tdm.shape}')
            mtype = type(sample_tdm)
            logging.info(f'Type of sample matrix: {mtype}')
            dlen = len(dictionary)
            logging.info(f'Length of dictionary: {dlen}')
            logging.info('Serializing sample tdm and dictionary...')
            pickle.dump(dictionary, open('dictionary.p', 'wb'))
            pickle.dump(sample_tdm, open('sample_tdm.p', 'wb'))
        else:
            dictionary = pickle.load(open('dictionary.p', 'rb'))
            sample_tdm = pickle.load(open('sample_tdm.p', 'rb'))
        
        # Calculate the weights and write them to the scorefile
        logging.info('Calculating weights...')
        ## Write header for scorefile
        infile.seek(0)
        header = next(reader)
        score_header = header[:3] + header[5:7] + ['adjusted_alignment_score']
        score_writer.writerow(score_header)
        
        start = time()
        for i,row in enumerate(reader):

            matched_text = matches_only(row[3], row[4])
            similarity_score = calc_similarities(matched_text, sample_tdm, 
                                                 dictionary, stemmer)
            if row[2] == '':
                adjusted_score = ''
            else:
                adjusted_score = float(row[2]) * (1 - similarity_score)
            
            out_row = row[:3] + row[5:7] + [adjusted_score]

            if i % 10**6 == 0:
                t = time() - start
                start = time()
                perc = round((i / m) * 100, 2)
                logging.info(f'{perc} percent done. This batch (10^6) took {t}')
                
