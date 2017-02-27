import multiprocessing as mp
from b2b_alignment import get_bill_alignments
import os
import csv


def collect_results():

    # If master files don't exist, create them
    if not os.path.exists(ALIGNMENT_MASTER_FILE):
        with open(ALIGNMENT_MASTER_FILE, 'w') as outfile:
            header = ('left_id,right_id,score,left_alignment_text,right_ali'
                      'gnment_text,lucene_score,max_lucene_score,compute_ti'
                       'me\n')
            outfile.write(header)

    if not os.path.exists(BILL_STATUS_FILE):
        with open(BILL_STATUS_FILE, 'w') as outfile:
            outfile.write('bill_id,status,time,n_bills,n_successfull\n')

    # Bill status
    status_dir = os.path.join(OUTPUT_DIR, "bill_status")
    with open(BILL_STATUS_FILE, 'a+') as outfile:
        for file in os.listdir(status_dir):
            f = os.path.join(status_dir, file)
            with open(f, 'r') as infile:
                line = infile.read()
                outfile.write(line)
            os.remove(f)

    # Alignments
    alignment_dir = os.path.join(OUTPUT_DIR, "alignments")
    with open(ALIGNMENT_MASTER_FILE, 'a+') as outfile:
        for file in os.listdir(alignment_dir):
            f = os.path.join(alignment_dir, file)
            with open(f, 'r') as infile:
                for line in infile:
                    outfile.write(line)
            os.remove(f)

if __name__ == "__main__":


    # =====================================================================
    # Config
    # =====================================================================
    BILL_IDS = 'bill_ids.txt'
    N_RIGHT_BILLS = 500
    MATCH_SCORE = 3
    MISMATCH_SCORE = -2
    GAP_SCORE = -3
    OUTPUT_DIR = '../data/aligner_output/'
    BILL_STATUS_FILE = os.path.join(OUTPUT_DIR, 'bill_status.csv')
    ALIGNMENT_MASTER_FILE = os.path.join(OUTPUT_DIR, 'alignments.csv')
    ES_IP = "http://localhost:9200/"
    # =====================================================================

    def align(bill_id):
        get_bill_alignments(bill_id, N_RIGHT_BILLS, MATCH_SCORE, MISMATCH_SCORE,
                            GAP_SCORE, OUTPUT_DIR, ES_IP)


    ### Get bills that already have been processed
    processed_bills = set()
    if os.path.exists(BILL_STATUS_FILE):
        with open(BILL_STATUS_FILE, 'r', encoding='utf-8') as csvfile:
            reader = csv.reader(csvfile, delimiter=',', quotechar='"')
            for row in reader:
                if row[1] == "successful":
                    processed_bills.update([row[0]])

    temp = open(BILL_IDS).readlines()
    all_bills = [e.strip('\n') for e in temp]
    bill_list = [e for e in all_bills if e not in processed_bills]
    
    print("Starting with {} bills...".format(len(bill_list)))
    pool = mp.Pool(processes=10)

    try:
        results = pool.map(align, bill_list)
    finally:
        collect_results()
