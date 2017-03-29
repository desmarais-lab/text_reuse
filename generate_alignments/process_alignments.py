import re
import Stemmer
# Generate the reweigted scores

# - Split the alignment file into alignment text and score file
# - Take a 



def matches_only(left_text, right_text):
    '''
    Return the matching tokens of two alignments
    '''
    out = []
    schar = re.compile('[^A-Za-z]')

    for left, right in zip(left_text.split(), right_text.split()):
        left = schar.sub('', left)
        right = schar.sub('', right)

        if left == right:
            out.append(left)

    return out

def proc_text(word_list, stemmer):

    out = [None] * len(word_list)
    for i,word in enumerate(word_list):
        out[i] = stemmer(word.lower())
    
    return out

if __name__ == "__main__":


    ALIGNMENT_OUTPUT = ('/storage/home/fjl128/scratch/text_reuse/aligner_output/'
                       'alignments.csv')

