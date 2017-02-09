from __future__ import division
import numpy as np
from numba import jit
import itertools
import timeout_decorator

class TimeOutError(Exception):
    pass

def _transform_text(a, b):
    """Converts a list of words into an numpy array of integers used by the alignment algorithm
    Keyword arguments:
    a -- string
    b -- string
    """
    
    a = a.split()
    b = b.split()

    word_map = dict()
    id = 1
    for w in itertools.chain(a,b):
        if w in word_map:
            continue
        else:
            word_map[w] = id
            id +=1
    
    a_ints = np.array([word_map[w] for w in a],dtype = int)
    b_ints = np.array([word_map[w] for w in b],dtype = int)

    return a_ints, b_ints, word_map

@timeout_decorator.timeout(5, timeout_exception=TimeOutError)
def align(left, right, match, mismatch, gap):
    '''
    description:
        find alignments between two documents
    args:
        left_sections: a list of lists of words
        right_sections: a list of lists of words (usually just a list of a list of words)

    returns:
        alignment object
    '''

    left_ints, right_ints, word_map = _transform_text(left, right)
    
    m = len(left_ints) + 1
    n = len(right_ints) + 1

    score_matrix = np.zeros(shape=(m, n), dtype=float)
    scores = np.zeros(shape=(4), dtype=float)
    pointer_matrix = np.zeros(shape=(m,n), dtype=int)
    
    score_matrix, pointer_matrix = _compute_matrix(left_ints, right_ints, match, 
                                                   mismatch, gap, score_matrix,
                                                   scores, pointer_matrix)
    
    i,j = np.unravel_index(score_matrix.argmax(), score_matrix.shape)
    l, r = _backtrace(left_ints, right_ints, score_matrix, pointer_matrix, i, j)

    reverse_word_map = {v:k for k,v in word_map.items()}
    reverse_word_map[-1] = "-" 
    
    l = [reverse_word_map[w] for w in l]
    r = [reverse_word_map[w] for w in r]
    score = score_matrix[i, j]

    return [score, " ".join(list(reversed(l))), " ".join(list(reversed(r)))]

@jit(nopython=True)
def _compute_matrix(left, right, match_score, mismatch_score, gap_score,
                    score_matrix, scores, pointer_matrix):
    '''
    description:
        create matrix of optimal scores
    args:
        left: an array of integers
        right: an array of integers
        match_score: score for match in alignment
        mismatch_score: score for mismatch in alignment
        gap_score: score for gap in alignment
        score_matrix: mxn matrix (float)
        pointer_matrix: mxn matrix (int)
        scores: 1x4 vector (float)
    returns:
        matrix representing optimal score for subsequences ending at each index
        pointer_matrix for reconstructing a solution
    '''

    m = len(left) + 1
    n = len(right) + 1
    
    for i in range(1, m):
        for j in range(1, n):
            
            if left[i-1] == right[j-1]:
                scores[1] = score_matrix[i-1,j-1] + match_score
            else:
                scores[1] = score_matrix[i-1,j-1] + mismatch_score

            scores[2] = score_matrix[i, j - 1] + gap_score
            
            scores[3] = score_matrix[i - 1, j] + gap_score
    
            max_decision = np.argmax(scores)

            pointer_matrix[i,j] = max_decision
            score_matrix[i,j] = scores[max_decision]
    
    return score_matrix, pointer_matrix


@jit(nopython=True)
def _backtrace(left, right, score_matrix, pointer_matrix, i, j):
    '''
    description:
        backtrace for recovering solution from dp matrix
    args:
        left: an array of integers
        right: an array of integers
        score_matrix matrix representing optimal score for subsequences ending at each index
        pointer_matrix for reconstructing a solution
    returns:
        left_alignment: array of integers
        right_alignment: array of integers
        score: score of alignment
        align_index: dictionary with indices of where alignment occurs in left and right
    '''

    #to get multiple maxs, just set score_matrix.argmax() to zero and keep applying argmax for as many as you want
    decision = pointer_matrix[i,j]
    
    m = len(left)
    n = len(right)

    left_alignment = np.zeros((m+n), dtype=np.int64)
    right_alignment = np.zeros((m+n), dtype=np.int64)
    l = 0
    r = 0

    while decision != 0 and i > 0 and j > 0:
        if decision == 1: #do not insert space
            i -= 1
            j -= 1
            left_alignment[l] = left[i]
            right_alignment[r] = right[j]
            l += 1
            r += 1
        elif decision == 2: #insert space in right text
            j -= 1
            right_alignment[r] = right[j]
            left_alignment[l] = -1
            l += 1
            r += 1
        elif decision == 3: #insert space in left text
            i -= 1
            left_alignment[l] = left[i]
            right_alignment[r] = -1
            l += 1
            r += 1

        #update decision
        decision = pointer_matrix[i,j]
   
    left_alignment = left_alignment[:l]
    right_alignment = right_alignment[:r]

    return left_alignment, right_alignment
