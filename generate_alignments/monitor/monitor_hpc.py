import re
import subprocess
from time import sleep

def update():
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
            response = subprocess.getoutput("qstat -u {}".format('fjl128'))
        except subprocess.CalledProcessError as error:
            if ntry > 5:
                raise
            time.sleep(10)
            pass

    # Get the parsed job list
    jobs = _parse_output(response)

    out = {
            'batch': {
                'running': 0,
                'queued': 0
                },
            'open': {
                'running': 0,
                'queued': 0
                }
            }

    for j in jobs:
        if j['status'] == 'R':
            out[j['queue']]['running'] += 1
        if j['status'] == 'Q':
            out[j['queue']]['queued'] += 1

    return out
            


def _parse_output(output):
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

    split_regex = re.compile(r'\s+')
    lines = output.split('\n')
    # Delete output header
    del lines[:5]
    jobs = [] 
    for line in lines:
        els = split_regex.split(line)
        try:    
            j = {"id_": els[0], "user": els[1], "queue": els[2], "name": els[3],
                 "status": els[9], "elapsed_time": els[10]}    
            jobs.append(j)
        
        except IndexError:
            pass

    return jobs


if __name__ == "__main__":
    OUTFILE = 'job_stats.csv'

   # with open(OUTFILE, 'a+') as outfile:
   #     outfile.write('open_running,open_queued,batch_running,batch_queued\n')

    while True:
        status = update()
        stats = [status['open']['running'], status['open']['queued'],
                status['batch']['running'], status['batch']['queued']]

        print(('Open:\nrunning:{}\nqueued:{}\n\n'
               'Batch:\nrunning:{}\nqueued:{}\n\n').format(*stats))

        with open(OUTFILE, 'a+') as outfile:
            outfile.write('{},{},{},{}\n'.format(*stats))

        sleep(10) 

    

