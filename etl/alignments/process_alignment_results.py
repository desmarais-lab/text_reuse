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

 
class AlignmentMatchText(object):
    '''
    Alignment class

    Defines an iterator over an alignment json file, that returns just the
    matched text of the alignment as a list
    '''
    
    def __init__(self, infile, stemmer, remove_same_state):
        self.infile = infile
        self.exclude = set(['', ' '])
        self.size = 0
        self.dictionary = corpora.Dictionary()
        self.stemmer = stemmer
        self.remove_same_state = remove_same_state
        self.schar = re.compile('[^A-Za-z]')


    def __iter__(self):
        with io.open(self.infile, 'r', encoding='utf-8') as infile:
            
            first = True
            for i,line in enumerate(infile):
                s = time.time()
                doc = self._json_from_line(line, i) 
                try:
                    alignments = doc['alignment_results']
                    left_doc_id = doc['query_document_id']
                    left_state = left_doc_id[0:2]
                    
                except KeyError:
                  continue

                for right_doc in alignments:


                    right_doc_id = right_doc['document_id']
                    right_state = right_doc_id[0:2]
                    
                    lucene_score = right_doc['lucene_score'] 


                    if self.remove_same_state and left_state == right_state:
                        continue

                    for b in right_doc['alignments']:
                        out = self._matches_only(b['left'], b['right'])
                        
                        align_score = b['score']
                         
                        # Update the dictionary
                        out_proc = self._proc_text(out)
                        self.dictionary.add_documents([out_proc])

                        out = ' '.join(out)
                        if out in self.exclude:
                            out = '_'
                        yield {'left_id': left_doc_id,
                               'right_id': right_doc_id,
                               'text': out,
                               'lscore': lucene_score,
                               'ascore': align_score,
                               'first': first}
                        self.size += 1

                        # Flag for first entry
                        first = False

                    # Reset flag for first entry (of a left bill)
                    first = True

    def _proc_text(self, word_list):
        out = []
        for word in word_list:
            word = self.stemmer(word.lower())
            out.append(word)
        return(out)
        

    def _matches_only(self, left_text, right_text):
        out = []
        for left, right in zip(left_text, right_text):
            left = self.schar.sub('', left)
            right = self.schar.sub('', right)

            if left == right:
                out.append(left)
            else:
                continue
        return(out)

    def _json_from_line(self, line, line_number):
        try:
            doc = json.loads(line)
            return doc
        except Exception as e:
            print('An exception occured in line {}: {}'.format(line_number, e))
        return None

def _proc_text(word_list):
    out = []
    for word in word_list:
        word = self.stemmer(word.lower())
        out.append(word)
    return(out)




if __name__ == "__main__":

    start = time.time()

    # Set parameters
    ## Files
    FULL_ALIG_FILE = '../../data/alignments_new/alignments_1000_sample.json'
    ALIG_SCORE_FILE = '../../data/alignments_new/alignments_1000_sample.csv'
    ALIG_TEXT_FILE = '../../data/alignments_new/alignment_match_text.csv' 
    LUCENE_SCORE_FILE = '../../data/alignments_new/lucene_scores_1000_sample.csv'
    ADJ_SCORE_FILE = '../../data/alignments_new/alignments_1000_adjusted_sample.csv'
    
    ## Options
    remove_same_state = True
    
    # Make a list of the alignments and collect the vocabulary
    # Remove same state alignments (if set to true)
    # Generate the alignment score csv
    # Generate the lucene score csv

    stemmer = Stemmer.Stemmer('english').stemWord
    alignments = AlignmentMatchText(FULL_ALIG_FILE, stemmer, remove_same_state)
    
    print('Creating dictionary and output files...')
    with io.open(ALIG_TEXT_FILE, 'w', encoding='utf-8') as align_file,\
            io.open(ALIG_SCORE_FILE, 'w', encoding='utf-8') as align_score_file,\
            io.open(LUCENE_SCORE_FILE, 'w', encoding='utf-8') as lucene_score_file:
        
        out_line = '{left_doc_id},{right_doc_id},{entry}\n'

        # Write headers
        align_file.write(out_line.format(left_doc_id='left_doc_id',
                                              right_doc_id='righ_doc_id',
                                              entry='match_text'))

        align_score_file.write(out_line.format(left_doc_id='left_doc_id',
                                               right_doc_id='righ_doc_id',
                                               entry='alignment_score'))

        lucene_score_file.write(out_line.format(
            left_doc_id='left_doc_id',
            right_doc_id='righ_doc_id',
            entry='lucene_score'))


        for n_align,a in enumerate(alignments):

            # If is first entry write lucene score to file:
            if a['first']:
                lucene_score_file.write(out_line.format(
                    left_doc_id=a['left_id'],
                    right_doc_id=a['right_id'],
                    entry=a['lscore']))

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
    alignments.dictionary.save("../../data/alignments_new/dictionary.dict")
    
    # Pass through the data and generate bow representations of the 2 samples
    print('Generating random samples...')
    with io.open(ALIG_TEXT_FILE, 'r', encoding='utf-8') as infile: 
        # bow arrays
        samp1_bow = []
        samp2_bow = []

        # array counter
        s1 = 0
        s2 = 0
                
        for idx, line in enumerate(infile):

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
        pickle.dump(compmat, open("compmat.p", "wb"))
        pickle.dump(alignments.dictionary, open("dictionary.p", "wb"))


    print('Calculating weights...')
    # Pass through the data again and calculate cosine similarities between each 
    # alignment text and each row of the 2 vectors


    # Split up the file
    n_chunks = 80
    #chunk_dir = '/storage/home/fjl128/scratch/text_reuse'
    chunk_dir = 'temp/'
    fstem = 'alignments_chunk_{}.csv'


    # open file handles
    handles = []
    for i in range(n_chunks):
        fname = os.path.join(chunk_dir, fstem.format(i))
        handles.append(io.open(fname, 'w', encoding='utf-8'))

 
    with io.open(ALIG_TEXT_FILE, 'r', encoding='utf-8') as infile:

        for idx, line in enumerate(infile):
            
            #skip header
            if idx == 0:
                continue

            i = idx % n_chunks
            handles[i].write(line)

        
        # Close file connections
        for i in range(n_chunks):
            handles[i].close()
 
        
        # Generate pbs jobs
        with io.open('pbs_temp.txt', 'r') as tempfile:
            template = tempfile.read()

        # Submit jobs
        for i in range(n_chunks):
            fname = os.path.join(chunk_dir, fstem.format(i))
            job = template.format(input_file=fname)
            fjob = 'align_weight_{}.pbs'.format(i)
            with io.open(fjob, 'w') as jobfile:
                jobfile.write(job)
            # Submit job
            subprocess.check_output(['qsub', fjob])
            print('submitted {}'.format(fjob))
            time.sleep(2)
            os.remove(fjob)   
