import threading
import os
import queue
import sys

from time import sleep, time

if __name__ == "__main__":
    
    FILEDIR = sys.argv[1]
    OUTFILE = sys.argv[2]
    wt = 4*60*60
        
    while True:
        files = os.listdir(FILEDIR)
        print('processing {} files'.format(len(files)))

        for f in files:
            sleep(0.01)
            # Only use files that are not beeing written in at the moment
            fpath = os.path.join(FILEDIR, f)
            since_last_mod = time() - os.stat(fpath).st_mtime
            if since_last_mod < wt:
                continue
            with open(fpath, 'r', encoding='utf-8') as infile,\
                 open(OUTFILE, 'a+', encoding='utf-8') as outfile:
                for line in infile:
                    outfile.write(line)

            os.remove(fpath)
            #print('Processed {}'.format(f))

        sleep(60)
