import sys
import json
import Stemmer
import re
import logging
import pickle
import os
import time

import pandas as pd
import scipy.sparse as sps

from sklearn.metrics.pairwise import cosine_similarity
from gensim import corpora, matutils
from elasticsearch import Elasticsearch as ES
from elasticsearch import NotFoundError
from itertools import combinations

sys.path.append('../../generate_alignments/')
from text_cleaning import clean_document


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
    ids = pd.read_csv('../../data/ncsl/ncsl_data_from_sample_matched.csv')
    ids = ids[ids['matched_from_db'] != 'mo_2012_HB1315']
    ids = ids.reindex()

    if not os.path.isfile(BILL_CACHE):
        # Initialize database for bill retrieval
        es = ES("localhost:9200", timeout=60)
        # Retrieve bills
        bills = [es.get_source(index="state_bills", id=id_, doc_type="_all")
                 for id_ in ids['matched_from_db']]

        print("Retrieved {} bills".format(len(bills)))
        pickle.dump(bills, open(BILL_CACHE, 'wb'))

    else:
        bills = pickle.load(open(BILL_CACHE, 'rb'))


    # Initialize text cleaner
    cleaner = TextCleaner()

    # Initialize dictionary
    dictionary = corpora.Dictionary()

    ids_with_text = []
    
    print('First pass to build the dictionary...')
    for i,bill in enumerate(bills):
        text = get_bill_text(bill)
        if text is None:
            continue
        ids_with_text.append(ids['matched_from_db'].iloc[i])
        
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
        tokens = cleaner.clean(text)
        corpus.append(dictionary.doc2bow(tokens))

        if i % 100 == 0:
            print(i)
    
    dtm = pd.DataFrame(matutils.corpus2dense(corpus, 
        num_terms=len(dictionary), num_docs=len(corpus)).transpose(),
        columns=[x[1] for x in dictionary.items()])

    # Calculate cosine similarity by topic
    grouped_dtm = dtm.groupby(list(ids['parent_topic']))
    grouped_ids = ids.groupby('parent_topic')

    # Store output (store the complete matrix w/o diagonal, in case 
    # left and right bill is different in the other datasets
    outline = '{},{},{}\n'
    with open('../../data/ncsl/cosine_similarities.csv', 'w') as outfile:
        outfile.write(outline.format('left_doc_id',
                                     'right_doc_id',
                                     'cosine_similarity'))

   
        out = []
        for dtm_group, id_group in zip(grouped_dtm, grouped_bill_ids):
            sim_mat = cosine_similarity(dtm_group[1])
            this_ids = id_group[1]
            for i in range(len(this_ids)):
                for j in range(len(this_ids)):
                    if i == j:
                        continue
                outfile.write(outline.format(this_ids.iloc[i], this_ids.iloc[j], 
                                             sim_mat[i][j]))
