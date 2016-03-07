#!/opt/anaconda/bin/python 
from __future__ import unicode_literals
import sys 
sys.path.append('../policy_diffusion/lid/')
from lid import LID
from text_alignment import AffineLocalAligner,LocalAligner
import database
import json
import base64
import codecs
import re
import logging
import os
import traceback
import sys
from utils.general_utils import deadline,TimedOutExc
from database import ElasticConnection
import time
import io


class NoneDocException(Exception):
    pass

@deadline(10000)
def get_alignments(query_doc, bill_id):
    result_docs=lidy.find_state_bill_alignments(query_doc,
            document_type="state_bill", split_sections=True, 
            state_id=bill_id[0:2], query_document_id=bill_id)
    return result_docs


def write_output(doc):
    with io.open(outfile_name, 'a+', encoding='utf-8') as outfile:
	outfile.write(unicode(json.dumps(doc)) + '\n')


if __name__ == "__main__":

    t = time.time() 

    input_file_name = sys.argv[1]
    output_dir = sys.argv[2]

    ES_IP = "54.244.236.175" 

    #configure logging
    logfile_name = 'b2b_logfile_job_{}.log'.format(re.sub('[^0-9]', '',
        input_file_name))
    outfile_name = os.path.join(output_dir, 
	'alignment_results_{}.json'.format(re.sub('[^0-9]', '',input_file_name)))
    
    log_path = os.path.join(os.environ['TEXT_REUSE'], 
         	'generate_alignments/logs', logfile_name)

    logging.basicConfig(filename=log_path,level=logging.DEBUG)
    logging.getLogger('elasticsearch').setLevel(logging.ERROR)
    logging.getLogger('urllib3').setLevel(logging.ERROR)
    logging.getLogger('json').setLevel(logging.ERROR)
 
    # Initialize aligner
    aligner = AffineLocalAligner(match_score=4, mismatch_score=-1, gap_start=-3, 
                                 gap_extend = -1.5)

    # Initialize Elastic Search connectino
    ec = ElasticConnection(host = ES_IP)
    
    # Initialize LID
    lidy = LID(query_results_limit=1000, elastic_host=ES_IP, 
               lucene_score_threshold=0, aligner=aligner)

    # Wipe the outfile in case it already exists
    with io.open(outfile_name, 'w+', encoding='utf-8') as outfile:
	outfile.write(unicode())

    # Loop through the input files and get alignments
    with io.open(input_file_name, 'r') as infile: 

        for line in infile:

            try:
                bill_id = line.strip('\n') 

                # Retrieve left bill
                query_doc =  ec.get_bill_by_id(bill_id)['bill_document_last']         

                # Retrieve all candidate right bills and align
                result_doc = get_alignments(query_doc,bill_id)

                # Dump out the resutls
		write_output(result_doc)


            except (KeyboardInterrupt, SystemExit):
                raise
    
            except NoneDocException: 
                m = "none doc error query_id {0}: {1}".format(bill_id, "None doc error")
                logging.error(m)
		write_output({"query_document_id": bill_id,"error":"none doc error"})

            except TimedOutExc: 
                m = "timeout error query_id {0}: {1}".format(bill_id, "timeout error")
                logging.error(m)
                write_output({"query_document_id": bill_id,"error":"timeout error"})

            except:
                trace_message = re.sub("\n+", "\t", traceback.format_exc())
                trace_message = re.sub("\s+", " ", trace_message)
                trace_message = "<<{0}>>".format(trace_message)
                m = "random error query_id {0}: {1}".format(bill_id, trace_message)
                logging.error(m)
                write_output({"query_document_id": bill_id,"error":"trace_message"})

    print "Finished successfully in {}".format(time.time() - t)
