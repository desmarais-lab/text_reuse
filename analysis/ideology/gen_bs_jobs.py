from __future__ import unicode_literals, division

import io
import subprocess
import math
import os
import time
import sys

# Get mode from cline argument
if sys.argv[1] == "all":
    specific_job = None
    BASE = False
elif sys.arrv[1] == "base":
    specific_job = None
    BASE = True
else:
    try:
        specific_job = int(sys.argv[1])
    except ValueError:
        raise ValueError('Invalid mode argument')
    BASE = False

# Load template file
with io.open('bs_reg_temp.txt', 'r') as infile:
        template = infile.read()


if not BASE:
    print("Generating bootstrap jobs...")
    N_PROC = 80 # number of processes to start
    N_BS = 1040 # number of bootstrap iterations

    n_per_job = int(math.ceil(N_BS / N_PROC)) # number of iterations per job
    print('{} iterations per job'.format(n_per_job))

    # Bootstrap jobs
    for n in range(N_PROC):
        if specific_job is not None:
            if n != specific_job:
                continue
        job = template.format(mode = "bootstrap",
                              job_number = n,
                              n_iter = n_per_job)
        job_file = "bs_job_{}.pbs".format(n)
        with io.open(job_file, 'w') as outfile:
            outfile.write(job)
        print("Submitted {}".format(n))
        x = subprocess.check_output(['qsub', job_file]) 
        time.sleep(0.5)
        os.remove(job_file)

else:
    print("Generating base model job...")
    # Base model job
    job = template.format(mode = 'base',
                          job_number = 0,
                          n_iter = 0)

    with io.open('base_job.pbs', 'w') as outfile:
        outfile.write(job)

    x = subprocess.check_output(['qsub', 'base_job.pbs'])
    time.sleep(0.5)
    os.remove('base_job.pbs')
