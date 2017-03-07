import threading
import os
import queue

from time import sleep, time

class Reader(threading.Thread):
    def __init__(self, filedir, q, waittime):
        super(Reader, self).__init__()
        self.filedir = filedir
        self.queue = q
        self.waittime = waittime

    def run(self):
        while True:
            if self.queue.full():
                sleep(0.05)
                continue

            # Check if there are new files
            files = os.listdir(self.filedir)
            for f in files:
                # Only use files that are not beeing written in at the moment
                fpath = os.path.join(self.filedir, f)
                since_last_mod = time() - os.stat(fpath).st_mtime
                if since_last_mod < self.waittime:
                    continue
                out = []
                with open(fpath, 'r') as infile:
                    for line in infile:
                        out.append(line)      
                self.queue.put(out)
                os.remove(fpath)

class Writer(threading.Thread):
    def __init__(self, outf, q):
        super(Writer, self).__init__()
        self.outfile = outf
        self.queue = q

    def run(self):
        while True:
            item = self.queue.get(block=True)
            with open(self.outfile, 'a+') as outfile:
                for line in item:
                    outfile.write(line)

if __name__ == "__main__":
    

    # Aligments
    alignment_queue = queue.Queue(100)
    alignment_reader = Reader('../data/aligner_output/alignments_test',
                              alignment_queue)
    alignment_writer = Writer('../data/aligner_output/alignments_test.csv',
                              alignment_queue, 5*60*60)
    
    # Bill status
    bs_queue = queue.Queue(100)
    bs_reader = Reader('../data/aligner_output/bill_status_test',
                       bs_queue, 5*60*60)
    bs_writer = Writer('../data/aligner_output/bill_status_test.csv',
                       bs_queue)

    alignment_reader.start()
    alignment_writer.start()
    bs_reader.start()
    bs_writer.start()


