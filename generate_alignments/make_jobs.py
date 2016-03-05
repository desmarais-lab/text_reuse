from __future__ import division, unicode_literals
import sys
import os
import io
import math
import shutil

# How many jobs split the task into
n_jobs = int(sys.argv[1])

# Text file containing all left bills in random order
id_file_name = sys.argv[2]

# Output directories
out_dirs = ['id_batches', 'pbs_scripts']

# Clear the output directories
for out_dir in out_dirs:
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    os.makedirs(out_dir)

## First split up the bill_id file in n_jobs parts
with io.open(id_file_name, 'r', encoding='utf-8') as id_file:
    
    ids = id_file.readlines()
    n_bills = len(ids)

    # Approx number of left bills per job (the last one will have less)
    n_per_job = math.ceil(n_bills / n_jobs)

    # Job counter
    k = 0
    
    outfile = None

    for i, id_ in enumerate(ids):

        if i % n_per_job == 0:
            
            # Close last connection if still exists
            if outfile is not None:
                outfile.close()

            # Increment job number
            k += 1

            # Create new file 
            new_file_name = 'id_batches/bill_ids_{}.txt'.format(k)
            
            # Open connection
            outfile = io.open(new_file_name, 'w+', encoding='utf-8')

        outfile.write(id_)


## Generate corresponding pbs jobs

# Load template
with io.open('job_template.txt', 'r') as template:
    pbs_template = template.read()

for i in range(1, (n_jobs + 1)):
    
    # Get the id input chunk for the job
    input_file_name = 'id_batches/bill_ids_{}.txt'.format(i)

    # Fill it into the template
    hpc_dir = "/storage/group/bbd5087_collab/text_reuse"
    err_log_file = "pbs_err_log_job_{}.log".format(i) 
    output_file = "alignments_{}.json".format(i)
    script = pbs_template.format(bill_id_chunk=input_file_name,
                                 main_dir_path=hpc_dir,
				 output_dir='../data/alignments/'
                                  )
    
    # Write the script to file
    script_file_name = 'pbs_scripts/b2b_job_{}.sh'.format(i)
    with io.open(script_file_name, 'w+', encoding='utf-8') as script_file:
        script_file.write(script)

