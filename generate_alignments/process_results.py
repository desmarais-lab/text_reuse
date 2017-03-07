import multiprocessing as mp
import csv
import queue
import os


def read(filename):
    out = []
    fpath = os.path.join(FILEDIR, filename)
    with open(fpath, 'r', encoding='utf-8') as infile:
        for line in infile:
            out.append(line)
    queue.put(row)
    os.remove(fpath)
    print('read {}'.format(filename))
         
def write(filename):
    while True:
        try:
            item = queue.get()
            print("Queue size: {}".format(queue.qsize()))
        except queue.Empty:
            sleep(0.01)
        with open(filename, 'a+', encoding='utf-8') as outfile:
            for line in item:
                outfile.write(line)



if __name__ == "__main__":

    # Config
    FILEDIR = '../data/aligner_output/alignments_test'
    OUTFILE = '../data/aligner_output/alignments_test.csv'

    files = os.listdir(FILEDIR)
    
    queue = queue.Queue()
    
    # Reader pool:
    pool = mp.Pool(processes=2) 
    pool.map_async(read, files) 
    write(OUTFILE)
