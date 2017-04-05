from elasticsearch import Elasticsearch
import json


def has_bill_text(b):
    if b["bill_document_last"] is None and b["bill_document_first"] is None:
        return False
    else:
        return True


if __name__ == "__main__":


    #==========================================================================
    # Config
    #==========================================================================
    HOST = 'localhost'
    PORT = 9200
    INDEX_NAME = 'state_bills'
    DATA_FILE = '../../data/initial_data/extracted_bills_with_sponsers.json' 
    MAPPING_FILE = "../../etl/database/state_bill_mapping.json"
    IDX_SET_FILE = "../../etl/database/state_bill_index.json"
    #==========================================================================

    # set up es connection
    es = Elasticsearch([{'host': 'localhost', 'port': 9200}], timeout=200)
    
    
    # Create the state_bill index
    if es.indices.exists(INDEX_NAME):
        print("Deleting {} index...".format(INDEX_NAME))
        es.indices.delete(index=INDEX_NAME)

    mapping_doc = json.loads(open(MAPPING_FILE).read())
    settings_doc = json.loads(open(IDX_SET_FILE).read())

    print("Creating {} index...".format(INDEX_NAME))    
    es.indices.create(index=INDEX_NAME, body=settings_doc)
    
    print("adding mapping for bill_documents")
    res = es.indices.put_mapping(index=INDEX_NAME, body=mapping_doc,
                                 doc_type="bill_document")

    bulk_data = []
    for i, line in enumerate(open(DATA_FILE)):

        if line == "null\n":
            continue

        json_obj = json.loads(line.strip())

        if not has_bill_text(json_obj):
            continue

        op_dict = {
                "index": {
                    "_index": INDEX_NAME,
                    "_type": "bill_document",
                    "_id": json_obj["unique_id"]
                }
        }

        bulk_data.append(op_dict)
        bulk_data.append(json_obj)
        if len(bulk_data) == 1000:
            print(i)
            es.bulk(index=INDEX_NAME, body=bulk_data)
            del bulk_data
            bulk_data = []


