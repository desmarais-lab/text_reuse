from database import ElasticConnection
from text_cleaning import clean_document
import nltk
import cPickle as pickle
from n_gram_scorer import clean_text
















ec = ElasticConnection(host = "54.244.236.175")

ngram_dict = {}

bill_ids = open("/home/mattburg/policy_diffusion/data/bill_ids.txt").read().splitlines()

#bill_ids = ["il_93rd_SB2798"]

n_gram_dict = {}
for i,bill_id in enumerate(bill_ids):
    percent_done = int(100*(float(i)/float(len(bill_ids))))
    if percent_done % 2 == 0 and percent_done > 0:
        print percent_done
    state_id = bill_id.split("_")[0]
    bill_doc = ec.get_bill_by_id(bill_id)['bill_document_last']

    if bill_doc is None:
        continue

    bill_doc = clean_document(bill_doc,doc_type = "state_bill",state_id = state_id)[0]
   
    
    for s in nltk.sent_tokenize(bill_doc):
        s = s.lower()
        s = s.split()
        
        s = clean_text(s)

        for i in range(len(s)-4):
            gram = " ".join(s[i:i+4])
            if gram in n_gram_dict:
                n_gram_dict[gram]+=1.0
            else:
                n_gram_dict[gram] = 1.0
    
        for i in range(len(s)-5):
            gram = " ".join(s[i:i+5])
            if gram in n_gram_dict:
                n_gram_dict[gram]+=1.0
            else:
                n_gram_dict[gram] = 1.0




pickle.dump(n_gram_dict,open("/z/mattburg_data/text_reuse_project/ngram_dict.p",'w'))

