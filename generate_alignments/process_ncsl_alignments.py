import Stemmer
import os 
import csv
import logging
import pickle
import sys

import numpy as np
import scipy.sparse as sps

from gensim import corpora, matutils
from sklearn.metrics.pairwise import cosine_similarity
from multiprocessing import Pool
from generate_alignments import matches_only, proc_text, calc_similarities




if __name__ == "__main__":

    # Config
    DATA_DIR = '../data/aligner_output/'
    ALIGNMENT_OUTPUT = os.path.join(DATA_DIR, 'ncsl_alignments.csv')
    SCORES = os.path.join(DATA_DIR, 'ncsl_alignments_notext.csv')

    n = 1000 # size of comparison samples
    stemmer = Stemmer.Stemmer('english').stemWord 
    
    logging.basicConfig(level=logging.INFO)

    with open(ALIGNMENT_OUTPUT, 'r', encoding='utf-8') as infile,\
         open(SCORES, 'w') as scorefile:
        
        reader = csv.reader(infile, delimiter=',', quotechar='"')
        score_writer = csv.writer(scorefile, delimiter=',', quotechar='"',
                                  quoting=csv.QUOTE_MINIMAL)

        # Count total number of rows in data
        m = sum([1 for row in reader])
        infile.seek(0)
        
        logging.info(f'{m} alignments in {ALIGNMENT_OUTPUT}')

        # Next pass through the data. Generate dictionary and sample matrix

        np.random.seed(3468934)
        logging.info('Select sample alignments...')
        sample = set(np.random.choice(m, size=n, replace=False))

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
        
        sample_tdm = matutils.corpus2csc(sample_bow, 
                                         num_terms=len(dictionary), 
                                         num_docs=n)
        logging.info(f'Shape of sample matrix: {sample_tdm.shape}')
        mtype = type(sample_tdm)
        logging.info(f'Type of sample matrix: {mtype}')
        dlen = len(dictionary)
        logging.info(f'Length of dictionary: {dlen}')
       
        # Calculate the weights and write them to the scorefile
        logging.info('Calculating weights...')

        ## Write header for scorefile
        infile.seek(0)
        header = next(reader)
        score_header = header[:3] + ['adjusted_alignment_score']
        score_writer.writerow(score_header)
            
        pool = Pool(processes=10)
        results = pool.imap(process_alignment, reader, chunksize=10000)
        pool.close()
        
        # Write all rows to file
        for row in results:
            score_writer.writerow(row)
