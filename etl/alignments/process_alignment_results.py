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
        self.vocabulary = {}
        self.stemmer = stemmer
        self.remove_same_state = remove_same_state


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
                        continue
                        out = self._matches_only(b['left'], b['right'])
                        align_score = b['score']
                        
                        # Update the vocabulary
                        #self._update_vocab(out)

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
                print('this line: {}s'.format(time.time() - s))


    def _update_vocab(self, word_list):
        for word in word_list:
            word = self.stemmer(word)
            if word in self.vocabulary:
                self.vocabulary[word] += 1
            else:
                self.vocabulary[word] = 1

    def _matches_only(self, left_text, right_text):
        out = []
        for left, right in zip(left_text, right_text):
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

            continue
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



    print(alignments.size)
    print(time.time() - start)
    sys.exit() 

    # Take random samples 
    numpy.random.seed(3468934)
    sample_1 = np.random.randint(size=1000,low=0,high=n_align) 
    sample_2 = np.random.randint(size=1000,low=0,high=n_align) 
     
    with io.open(ALIG_TEXT_FILE, 'r', encoding='utf-8') as infile:
        pass

