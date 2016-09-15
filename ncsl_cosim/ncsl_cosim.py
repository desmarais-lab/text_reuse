from __future__ import unicode_literals, print_function, division
import sys
sys.path.append('../policy_diffusion/lid')
from lid import LID
from utils.text_cleaning import clean_document
from database import ElasticConnection
import json
import io
from gensim import corpora, matutils
import Stemmer
import scipy.sparse as sps
from sklearn.metrics.pairwise import cosine_similarity
import re
import logging
import cPickle as pickle
import os

class TextCleaner(object):

    def __init__(self):
        self.excl_chars = re.compile('[^0-9A-Za-z\s-]')
        self.stemmer = Stemmer.Stemmer("english")

    def _stem(self, word):
        return self.stemmer.stemWord(word)
 
    def clean(self, text):
        text = self.excl_chars.sub('', text.lower())
        tokens = text.split()
        tokens = [self._stem(t) for t in tokens]
        return tokens

def calc_cossim(bill_pair):
    pass

def get_bill_text(bill):
    text = bill['bill_document_last']
    if text is None:
        text = bill['bill_document_first']
    if text is None:
        return None
    else:
        return text



if __name__ == "__main__":

    BILL_CACHE = 'bills.p'
    
    # Load bill list
    with io.open('../data/ncsl/matched_ncsl_bill_ids.txt') as infile:
        ids = [s.strip('\n') for s in infile.readlines()]

    if not os.path.isfile(BILL_CACHE):
        # Initialize database for bill retrieval
        ES_IP = "54.244.236.175"
        elastic_connection = ElasticConnection(host=ES_IP, port=9200)
        # Retrieve bills
        bills = [elastic_connection.get_bill_by_id(id) for id in ids]
        pickle.dump(bills, io.open(BILL_CACHE, 'wb'))
    else:
        bills = pickle.load(io.open(BILL_CACHE, 'rb'))


    # Initialize text cleaner
    cleaner = TextCleaner()

    # Initialize dictionary
    dictionary = corpora.Dictionary()

    # Set up logging for gensim
    #logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s',
    #                    level=logging.INFO)
    ids_with_text = []
    
    print('First pass to build the dictionary...')
    for i,bill in enumerate(bills):
        text = get_bill_text(bill)
        if text is None:
            continue
        ids_with_text.append(ids[i])
        
        # clean and tokenize text
        tokens = cleaner.clean(text)
        
        # Update dictionary
        dictionary.add_documents([tokens])

        if i % 100 == 0:
            print(i)
   
    # Reduce vocabulary
    dictionary.filter_extremes(no_below=2, no_above=1.0, keep_n=None)

    print('Generate term document matrix...')
    corpus = []
    for i,bill in enumerate(bills):
        text = get_bill_text(bill)
        if text is None:
            continue
        tokens = cleaner.clean(text)
        corpus.append(dictionary.doc2bow(tokens))

        if i % 100 == 0:
            print(i)
    
    dtm = matutils.corpus2csc(corpus).transpose()

    print('Calculating similarities')
    csims = cosine_similarity(dtm)

    outline = '{},{},{}\n'
    with io.open('../data/ncsl/cosine_similarities.csv', 'w') as outfile:
        outfile.write(outline.format('left_doc_id',
                                     'right_doc_id',
                                     'cosine_similarity'))

        for i in range(len(ids_with_text)):
            for j in range(len(ids_with_text)):
                if j >= i:
                    break
                outfile.write(outline.format(ids[i], ids[j], 
                                             csims[i][j]))
