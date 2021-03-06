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
from multiprocessing import Pool

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


def process_alignment(row):

    try:
        matched_text = matches_only(row[3], row[4])
    except IndexError:
        return [None] * 6 

    similarity_score = calc_similarities(matched_text, sample_tdm, 
                                         dictionary, stemmer)
    if row[2] == '':
        adjusted_score = ''
    else:
        adjusted_score = float(row[2]) * (1 - similarity_score)
    out_row = row[:3] + row[5:7] + [adjusted_score]
    return out_row
    
            
if __name__ == "__main__":


    # Config
    DATA_DIR = '../data/aligner_output/'
    ALIGNMENT_OUTPUT = os.path.join(DATA_DIR, 'alignments_with_dups.csv')
    #ALIGNMENT_OUTPUT = os.path.join(DATA_DIR, 'test.csv')
    SCORES = os.path.join(DATA_DIR, 'alignments_notext.csv')
    DEDUPED = os.path.join(DATA_DIR, 'alignments.csv')

    n = 1000 # size of comparison samples
    stemmer = Stemmer.Stemmer('english').stemWord 
    
    logging.basicConfig(level=logging.INFO)
    
#    logging.info("Deduplicating alignments...")
#    with open(ALIGNMENT_OUTPUT, 'r', encoding='utf-8') as infile,\
#         open(DEDUPED, 'w') as dedupedfile:
#
#        reader = csv.reader(infile, delimiter=',', quotechar='"')
#        deduped_writer = csv.writer(dedupedfile, delimiter=',', quotechar='"',
#                                    quoting=csv.QUOTE_MINIMAL)
#
#        header = next(reader)
#        deduped_writer.writerow(header)
#        all_pairs = set()
#        for i,row in enumerate(reader):
#            ids = '_'.join(sorted([row[0], row[1]]))
#            if ids not in all_pairs:
#                deduped_writer.writerow(row)
#                all_pairs.update([ids])

#    del all_pairs

    with open(DEDUPED, 'r', encoding='utf-8') as infile,\
         open(SCORES, 'w') as scorefile:
        
        reader = csv.reader(infile, delimiter=',', quotechar='"')
        score_writer = csv.writer(scorefile, delimiter=',', quotechar='"',
                                  quoting=csv.QUOTE_MINIMAL)
 
        # Count total number of rows in data
        if not os.path.exists('n_alignments.p'):
            header = next(reader)
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
            
        pool = Pool(processes=10)
        results = pool.imap(process_alignment, reader, chunksize=10000)
        pool.close()
        
        # Write all rows to file
        for row in results:
            score_writer.writerow(row)
