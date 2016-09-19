from __future__ import unicode_literals, division

import io
import subprocess
import math
import os
import time

N_PROC = 80 # number of processes to start
N_BS = 1040 # number of bootstrap iterations

n_per_job = int(math.ceil(N_BS / N_PROC)) # number of iterations per job
print(n_per_job)

with io.open('bs_reg_temp.txt', 'r') as infile:
    template = infile.read()

nos = range(1, (N_PROC + 1))

# Bootstrap jobs
for n in nos:
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



# Base model job
job = template.format(mode = 'base',
                      job_number = 0,
                      n_iter = 0)

with io.open('base_job.pbs', 'w') as outfile:
    outfile.write(job)

x = subprocess.check_output(['qsub', 'base_job.pbs'])
time.sleep(0.5)
os.remove('base_job.pbs')
