## PBS job submission for text reuse project
#
# Author: Fridolin Linder

from __future__ import unicode_literals
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

    def __init__(self, user_id, allocation, num_jobs, bill_list, job_template, job_dir,
            sleep_time):
        self.split_regex = re.compile(r'\s+')
        self.status = None
        self.num_jobs = num_jobs
        self.running_jobs = 0
	self.user_id = user_id
        self.bill_queue = bill_list
        self.last_difference = 0
        self.template = job_template
        self.prog_f_name = 'mj_queue_prog.txt'
        self.allocation = allocation

        self.job_dir = job_dir
        if os.path.exists(self.job_dir):
            shutil.rmtree(self.job_dir)
            os.makedirs(self.job_dir)
        else:
            os.makedirs(self.job_dir) 

        self.sleep_time = sleep_time

    def _update_prog_file(self, job):
        '''
        Update the permanent progress file
        '''

        with io.open(self.prog_f_name, 'a+', encoding='utf-8') as progfile:
            progfile.write(job)
            progfile.write(u'\n')
            

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
                response = subprocess.check_output(['qstat', '-u', self.user_id])
            except subprocess.CalledProcessError as error:
                if ntry > 5:
                    raise
                rc = error.returncode
                print "Error in qsub in _submit_job(). Returncode: {}".format(rc) 
                print "Taking a break..."
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

        # Submit jobs until num_job is reached
        while c <= self.last_difference:
            c += 1
            new_job = self._make_job(self.bill_queue[0])
 
            # Try 5 times in 50 seconds, in case the qbs system is not reponsive
            ntry = 0
            response = None
            while response == None:
                try:
                    ntry += 1
                    response = subprocess.check_output(['qsub', new_job]) 

                except subprocess.CalledProcessError as error:

                    # Raise exception and halt program after 5 unsuccesful tries 
                    if ntry > 5:
                        raise

                    c -= 1
                    rc = error.returncode
                    print "Error in qsub in _submit_job(). Returncode: {}".format(rc) 
                    print "Taking a break..."
                    # Wait before re-trying
                    time.sleep(60)
                    pass

            self._update_prog_file(self.bill_queue[0])
            self.bill_queue.pop(0)
            time.sleep(self.sleep_time)


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
                                   allocation=self.allocation)
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


if __name__ == "__main__":
   
    # Parameteres
    USER_ID = 'fjl128'
    NUM_JOBS = 85
    BILL_IDS = 'bill_ids_batch_2.txt'
    ALLOCATION = 'bbd5087-himem_collab'

    # Prepare inputs

    ## Temp job file directory
    job_dir = 'pbs_scripts_' + ALLOCATION

    ## List of bills to be processed (bill ids - ids in progress file)
    temp = io.open('mj_queue_prog.txt').readlines()
    processed_bills = set([e.strip('\n') for e in temp])
    temp = io.open(BILL_IDS).readlines()
    all_bills = [e.strip('\n') for e in temp]
    bill_list = [e for e in all_bills if e not in processed_bills]

    # Read the job template from file
    with io.open('single_bill_job_template.txt') as templatefile:
        template = templatefile.read()
    
    # Initialize Queue monitor
    print 'Initialize queue with {} jobs'.format(len(bill_list))
    queue = PBSQueue(user_id=USER_ID, 
                     num_jobs=NUM_JOBS, 
                     bill_list=bill_list, 
                     job_template=template, 
                     job_dir=job_dir, 
                     sleep_time=2, 
                     allocation=ALLOCATION)

    # Main loop
    while True:
        queue.update()
	ts = time.time()
	st = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
        
        if len(queue.bill_queue) == 0:
            print "Finished"
            break

        if queue.running_jobs >= queue.num_jobs:
            print "[{}]: {} jobs running. No new jobs.".format(st, queue.running_jobs)
            time.sleep(5)
        else:
            queue.submit_jobs()
	    print "[{}]: {} jobs running. Submitted {} jobs".format(st, queue.running_jobs,
                                                                queue.last_difference)
            time.sleep(60)
            queue.clear_job_dir()
