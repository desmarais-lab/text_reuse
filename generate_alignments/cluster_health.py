



from elasticsearch import Elasticsearch
from pprint import pprint
import sys


es = Elasticsearch('http://elasticsearch.dssg.io:9200/', timeout=10, 
                    retry_on_timeout=True, max_retries=100)
try:
    pprint(es.cluster.health())
    print(es.ping())
except:
    print("exception occurred")


sys.exit()

doc = es.get_source(index="state_bills", id='ky_2013RS_HB262', doc_type="_all")
pprint(doc.keys())
   
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
