import sys
from elasticsearch import Elasticsearch as ES
sys.path.append('../../generate_alignments')
from b2b_alignment import get_bill_document



if __name__ == "__main__":

    # DB connection
    es = ES("localhost:9200", timeout=60, retry_on_timeout=True, max_retries=15)

    id_ = sys.argv[1]

    source = es.get_source(index="state_bills", id=id_, doc_type="_all")
    
    doc = get_bill_document(source)

    print(doc)
