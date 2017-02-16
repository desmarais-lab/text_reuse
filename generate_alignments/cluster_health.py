from elasticsearch import Elasticsearch
from pprint import pprint
import sys
import numpy as np


es = Elasticsearch('http://localhost:9200/', timeout=3, 
                    retry_on_timeout=True, max_retries=1)

pprint(es.cluster.health())
print(es.ping())


with open('bill_ids.txt') as infile:
    ids = [x.strip('\n') for x in infile]
#
#o = np.zeros((len(ids)))

#for i, id_ in enumerate(ids): 
#    doc = None
#    s = 'failed'
#    doc = es.get_source(index="state_bills", id=id_, doc_type="_all")
#    if doc is not None:
#        o[i] = 1
#        s = 'worked'
#
#    print('{}: {}, {}'.format(s, i, id_))
#
#print(o.sum())
#sys.exit()   


doc = es.get_source(index="state_bills", id="ky_2013RS_HB262", doc_type="_all")

query = {
    "query": {
        "bool": {
            "must": [
                {
                    "more_like_this": {
                        "fields": ["bill_document_last.shingles"],
                        "like_text": "this is some example text that serves th",
                        "max_query_terms": 25,
                        "min_term_freq": 1,
                        "min_doc_freq": 2,
                        "minimum_should_match": 1
                    }
                },
                {
                    "bool": { "must_not": { "match": {
                                "state": "ca"
                            }
                        }
                    }
                }
            ]
        }
    }
}

res = es.search(index="state_bills", body=query, size=500)
print(res.keys())
print(len(res['hits']['hits']))


