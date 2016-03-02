#Module that contains functions to score bill text using n_gram_dict generated
#by the n_gram_counter.p script

import cPickle as pickle
import numpy as np



##fix me tommorow, count using the dict 
FOUR_GRAM_TOTAL_COUNT = 50000000000
FIVE_GRAM_TOTAL_COUNT = 10000000000


def clean_text(s):
    s = [w.rstrip(",;.") for w in s]
    s = [w for w in s if w.isalpha()]
    return s




class BoilerplateScorer():
    """Classifier that labels alignments as either substantive (1) or boilerplate (0)"""


    def __init__(self,n_gram_counts_path):
        """Keyword Args:

            idf_file_path: file path of the table that stores idf scores of the words
            
        """
        self._ngram_dict = pickle.load(open(n_gram_counts_path))
    
    def _get_ngram_counts(self,word_list):
        
        
        ngram_counts = []
        for i in range(len(word_list)-4+1):
            gram = " ".join(word_list[i:i+4])
            if gram in self._ngram_dict:
                ngram_counts.append(self._ngram_dict[gram])
        for i in range(len(word_list)-5+1):
            gram = " ".join(word_list[i:i+5])
            if gram in self._ngram_dict:
                ngram_counts.append(self._ngram_dict[gram])

        return ngram_counts
    
    def score_text(self,text):
        text = text.lower()
        text_list = text.split()
        text_list = clean_text(text_list)
        
        ngram_counts = self._get_ngram_counts(text_list)
        ngram_scores = [np.log(FOUR_GRAM_TOTAL_COUNT)/n for n in ngram_counts]

        return np.mean(ngram_scores)




def main():

    bp_score = BoilerplateScorer("/Users/mattburg/Desktop/ngram_subset_dict_lid.p")
    print bp_score.score_text("it is the purpose of this act to remove barriers to educational success imposed on children of active duty military personnel families because of frequent moves and deployment of their")
    print bp_score.score_text("it is the purpose of this act to remove") 

if __name__ == "__main__":
    main()






















