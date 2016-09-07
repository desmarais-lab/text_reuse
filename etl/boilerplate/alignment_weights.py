from __future__ import unicode_literals, division, print_function
import sys
import io
import json
from pprint import pprint
from multiprocessing import Pool
import numpy as np
import re
import operator





    
class AlignmentMatchText(object):
    '''
    Alignment class

    Defines an iterator over an alignment json file, that returns just the
    matched text of the alignment as a list
    '''
	
    def __init__(self, infile):
        self.infile = infile
        self.exclude = set(['', ' '])


    def __iter__(self):

        with io.open(self.infile, 'r', encoding='utf-8') as infile:
            
            c = 0 
            for i,line in enumerate(infile):
                
       		doc = self._json_from_line(line, i) 
                try:
                    alignments = doc['alignment_results']

                    left_doc_id = doc['query_document_id']

                    for right_doc in alignments:
                        
                        right_doc_id = right_doc['document_id']

                        if left_doc_id == right_doc_id:
                            print(left_doc_id, right_doc_id)
                            c += 1
                            continue
                        else:
                            continue

                        for b in right_doc['alignments']:

                            out = self._matches_only(b['left'], b['right'])
                            out = ' '.join(out)
                            if out in self.exclude:
                                out = '_'
                            yield left_doc_id, right_doc_id, out
                except KeyError:
                  continue
              
            print(i, c)

    def _matches_only(self, left_text, right_text):

	out = []
	for left, right in zip(left_text, right_text):
	    if left == right:
		out.append(left)
	    else:
		continue
	return(out)
 


    def _json_from_line(self, line, line_number):
	try:
	    doc = json.loads(line)
	    return doc
	except Exception as e:
	    print('An exception occured in line {}: {}'.format(line_number, e))
	    return None




if __name__ == "__main__":

    # Set parameters
    FULL_ALIG_FILE = '../../data/alignments_new/alignments_1000_sample.json'
    ALIG_SCORES_FILE = '../../data/alignments_new/alignments_1000_sample.csv'
    ALIG_TEXT_FILE = '../../data/alignments_new/alignment_match_text.csv' 

    
    # Make a list of the alignments
    alignments = AlignmentMatchText(FULL_ALIG_FILE)
    
    with io.open(ALIG_TEXT_FILE, 'w', encoding='utf-8') as outfile:
        
        line_temp = '{left_doc_id},{right_doc_id},{match_text}\n'

        # Write header
        outfile.write(line_temp.format(left_doc_id='left_doc_id',
                                       right_doc_id='righ_doc_id',
                                       match_text='match_text'))

        for a in alignments:
            out_line = line_temp.format(left_doc_id=a[0],
                                        right_doc_id=a[1],
                                        match_text=a[2])
            outfile.write(out_line)

