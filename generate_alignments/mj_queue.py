## PBS job submission for text reuse project
#
# Author: Fridolin Linder

import subprocess
import re
import os
import io
import glob
import time
import argparse
import datetime
import sys
import shutil
import csv


class PBSQueue(object):
    '''
    PBS personal queue class

    Monitors a users pbs job submissions.

    Arguments:
    ----------
    user_id: str, pbs user id.
    allocation: str, allocation name to submit to
    num_jobs: int, how many jobs sould be running in parallel
    bill_list: list, of bills to generate jobs for
    job_template: str, template with placeholder for allocation and input bill 
        job_dir: str, directory name to store temporary job files
    sleep_time: int, waiting time between submission of single jobs
    '''

    def __init__(self, user_id, allocation, num_jobs, bill_list, job_template, 
                 job_dir, sleep_time, n_right_bills, match, mismatch, gap, 
                 output_dir, es_ip, bill_status_file, alignment_master_file):

        self.split_regex = re.compile(r'\s+')
        self.status = None
        self.num_jobs = num_jobs
        self.running_jobs = 0
        self.user_id = user_id
        self.bill_queue = bill_list
        self.last_difference = 0
        self.template = job_template 
        self.allocation = allocation
        self.n_right_bills = n_right_bills
        self.match = match
        self.mismatch = mismatch
        self.gap = gap
        self.output_dir = output_dir
        self.es_ip = es_ip
        self.bill_status_file=bill_status_file
        self.alignment_master_file=alignment_master_file

        self.job_dir = job_dir

        if os.path.exists(self.job_dir):
            shutil.rmtree(self.job_dir)
            os.makedirs(self.job_dir)
        else:
            os.makedirs(self.job_dir) 

        self.sleep_time = sleep_time
   

    def update(self):        
        '''
        Update status of the queue.

        Checks the status of the users jobs in the pbs system.

        Arguments:
        ----------
        
        Returns:
        ---------
        Updates the running_jobs attribute of the queue
        '''
        # Request status through shell
        response = None
        ntry = 0
        # Try 5 times in 50 seconds, in case the pbs system is not responsive
        while response is None:
            try:
                ntry += 1
                response = subprocess.getoutput("qstat -u {}".format(self.user_id))
            except subprocess.CalledProcessError as error:
                if ntry > 5:
                    raise
                time.sleep(10)
                pass

        # Get the parsed job list
        jobs = self._parse_output(response)

        # Counte the number of jobs that are runnign or queued
        if self.allocation != "open":
            self.running_jobs = sum(j['status'] in ['R', 'Q'] and j['queue'] == "batch" for j in jobs)
        else:
            self.running_jobs = sum(j['status'] in ['R', 'Q'] and j['queue'] == "open" for j in jobs)

    def submit_jobs(self):
        '''
        Submit jobs until the desired amount of jobs is runnig

        Arguments:
        ---------
        None

        Returns:
        ----------
        None
        '''
        self.last_difference = self.num_jobs - self.running_jobs
        c = 1
        n_submitted = 0

        # Submit jobs until num_job is reached
        while c <= self.last_difference and len(self.bill_queue) >= 1:
            c += 1
            new_job = self._make_job(self.bill_queue[0])
 
            # Try 5 times in 50 seconds, in case the qbs system is not reponsive
            ntry = 0
            response = None
            while response == None:
                try:
                    ntry += 1
                    response = subprocess.getoutput("qsub {}".format(new_job))

                except subprocess.CalledProcessError as error:

                    # Raise exception and halt program after 5 unsuccesful tries 
                    if ntry > 5:
                        raise
                    c -= 1
                    # Wait before re-trying
                    time.sleep(10)
                    pass

            self.bill_queue.pop(0)
            n_submitted += 1
            time.sleep(self.sleep_time)

        return n_submitted


    def _parse_output(self, output):
        '''
        Parse output from qstat pbs commandline program
        
        Arguments:
        ----------
        output: str, output obtained from qstat command

        Returns:
        ---------
        list, of all jobs. Each job is represented as a dictionary conainting
            all relevant information.
        '''
        lines = output.split('\n')
        # Delete output header
        del lines[:5]
        jobs = [] 
        for line in lines:
            els = self.split_regex.split(line)
            try:    
                j = {"id_": els[0], "user": els[1], "queue": els[2], "name": els[3],
                     "status": els[9], "elapsed_time": els[10]}    
                jobs.append(j)
            
            except IndexError:
                pass

        return jobs

    def _make_job(self, bill_id):
        '''
        Generate a job from the template

        Arguments:
        ----------
        bill_id: str, unique database id of left bill

        Returns:
        ----------
        Generates a job file in self.job_dir and returns
        str, path/name of the jobfile
        '''
        job = self.template.format(bill_id=bill_id,
                                   allocation=self.allocation,
                                   n_right_bills=self.n_right_bills,
                                   match=self.match,
                                   mismatch=self.mismatch,
                                   gap=self.gap,
                                   output_dir=self.output_dir,
                                   es_ip=self.es_ip)
        bill_id = re.sub('[^A-Za-z0-9]', '_', bill_id)
        name = 'b2b_job_' + bill_id + '.sh'
        jobname = os.path.join(self.job_dir, name)
        with io.open(jobname, 'w+') as jobfile:
            jobfile.write(job)

        return jobname

    def clear_job_dir(self):
        '''
        Remove all temporary job files that have been submitted
        '''
        jobfiles = glob.glob(os.path.join(self.job_dir, "b2b_*"))
        for f in jobfiles:
            os.remove(f)
    
    def collect_results(self):

        # If master files don't exist, create them
        if not os.path.exists(self.alignment_master_file):
            with open(self.alignment_master_file, 'w') as outfile:
                header = ('left_id,right_id,score,left_alignment_text,right_ali'
                          'gnment_text,lucene_score,max_lucene_score,compute_ti'
                           'me\n')
                outfile.write(header)

        if not os.path.exists(self.bill_status_file):
            with open(self.bill_status_file, 'w') as outfile:
                outfile.write('bill_id,status,time,n_bills,n_successfull\n')

        # Bill status
        status_dir = os.path.join(self.output_dir, "bill_status")
        with open(self.bill_status_file, 'a+') as outfile:
            for file in os.listdir(status_dir):
                f = os.path.join(status_dir, file)
                with open(f, 'r') as infile:
                    line = infile.read()
                    outfile.write(line)
                os.remove(f)

        # Alignments
        alignment_dir = os.path.join(self.output_dir, "alignments")
        with open(self.alignment_master_file, 'a+') as outfile:
            for file in os.listdir(alignment_dir):
                f = os.path.join(alignment_dir, file)
                with open(f, 'r') as infile:
                    for line in infile:
                        outfile.write(line)
                os.remove(f)

def timestamp():
    ts = time.time()
    return datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')

if __name__ == "__main__":
    
    # =====================================================================
    # Config
    # =====================================================================
    USER_ID = 'fjl128'
    NUM_JOBS = 90
    BILL_IDS = 'bill_ids.txt'
    ALLOCATION = 'bbd5087-himem_collab'

    N_RIGHT_BILLS = 500
    MATCH_SCORE = 3
    MISMATCH_SCORE = -2
    GAP_SCORE = -3
    OUTPUT_DIR = '/storage/group/bbd5087_collab/text_reuse/data/aligner_output/'
    BILL_STATUS_FILE = os.path.join(OUTPUT_DIR, 'bill_status.csv')
    ALIGNMENT_MASTER_FILE = os.path.join(OUTPUT_DIR, 'alignments.csv')
    ES_IP = "http://elasticsearch.dssg.io:9200/"
    # =====================================================================

    ## Temp job file directory
    job_dir = 'pbs_scripts_' + ALLOCATION

    ## List of bills to be processed (bill ids - ids in progress file)
    
    ### Get bills that already have been processed
    processed_bills = set()

    if os.path.exists(BILL_STATUS_FILE):
        with open(BILL_STATUS_FILE, 'r', encoding='utf-8') as csvfile:
             reader = csv.reader(csvfile, delimiter=',', quotechar='"')
             for row in reader:
                 processed_bills.update([row[0]])
    temp = io.open(BILL_IDS).readlines()
    all_bills = [e.strip('\n') for e in temp]
    bill_list = [e for e in all_bills if e not in processed_bills]

    # Read the job template from file
    with io.open('single_bill_job_template.txt') as templatefile:
        template = templatefile.read()
    
    # Initialize Queue monitor
    print('Initialize queue with {} jobs'.format(len(bill_list)))
    queue = PBSQueue(user_id=USER_ID, 
                     num_jobs=NUM_JOBS, 
                     bill_list=bill_list, 
                     job_template=template, 
                     job_dir=job_dir, 
                     sleep_time=10, 
                     allocation=ALLOCATION,
                     n_right_bills=N_RIGHT_BILLS,
                     match=MATCH_SCORE,
                     mismatch=MISMATCH_SCORE,
                     gap=GAP_SCORE,
                     output_dir=OUTPUT_DIR,
                     es_ip=ES_IP,
                     bill_status_file=BILL_STATUS_FILE,
                     alignment_master_file=ALIGNMENT_MASTER_FILE
                     )

    # Main loop
    try:
        while True:
            queue.update()
            
            if len(queue.bill_queue) == 0:
                print("Finished")
                break

            if queue.running_jobs >= queue.num_jobs:
                print("[{}]: {} jobs running. No new jobs.".format(timestamp(), queue.running_jobs))
            else:
                n_submitted = queue.submit_jobs()
                print("[{}]: {} jobs running. Submitted {} jobs".format(timestamp(), queue.running_jobs,
                                                                        n_submitted))
            time.sleep(2)
            queue.clear_job_dir()

    except KeyboardInterrupt:
        print("[{}]: Terminating...".format(timestamp()))
        raise
    finally:        
        print("[{}]: Cleaning up...".format(timestamp()))
 
        queue.update()
        # Wait until all jobs are terminated, then collect results
        while queue.running_jobs > 0:
            print("[{}]: There are still jobs running. Waiting...".format(timestamp()))
            time.sleep(10)
            queue.update()

        queue.collect_results()
