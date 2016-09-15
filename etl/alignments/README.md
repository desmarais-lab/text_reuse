# ETL for alignment output


This directory contains scripts to process the big json output from the
alignment algorithm.

`process_alignment_results.py`:

Does multiple tasks:
1. Passes through `data/alignments_new/alignments_1000.json` and 1) extracts the
alignment score for each alignment and stores as a new csv line in
`data/alignments_new/alignments_1000.csv`, 2) For each bill pair extracts the
lucene score and stores it as a new csv line in
`data/alignments_new/lucene_scores_1000.csv`, 3) extracts each alignment text
(the matching part of the sequence) and writes it as new csv line in
`data/alignments_new/alignment_match_text.csv`, 4) builds a
`gensim.corpora.Dictionary` of the alignment text (for later bag of words use).
In all these steps same state alignments are excluded (since they are not used
in the paper).

2. Passes through `data/alignments_new/alignment_match_text.csv` and generates
two random samples of size $n$ (atm $n=1000$), stored as a
`scipy.sparse.csr_matrix` bag of words term document matrix. This matrix is
written to disk as `compmat.p` and the dictionary the bow representation is
based on, is stored as `dictionary.p`.

3. Passes through `data/alignments_new/alignment_match_text.csv` again, and
splits the file in `n_chunks` (atm 80) chunks for parallel processing.

4. Generates and submits `n_chunks` pbs scripts, passing the data chunk to
`alignment_weights.py`

Requires ~ 30h computing time.

`alignment_weights.py`:

Transforms each alignment text to a bow representation (based on the dictionary
generated in 1. and calculates the cosine similarity with each alignment in the
two samples generated in 2.. The scores are averaged for each sample and written
to `~/scratch/text_reuse/adjusted_alignments_*.csv` where * is the chunk ID.
Requires ~ 4h computing time


`weigh_scores.py`

Pulls the output files from the parallel `alignment_weight.py` threads together,
 weights the raw alignment scores by the weights and writes the adjusted scores
 to `data/alignments_new/adjusted_scores.csv`

`aggregate_scores.py`

Takes the reweighted scores and aggregates them to the bill-dyad level
(`data/alignments_new/bill2bill_scores.csv`) and to the state-dyad level
(`data/alignments_new/state2state_scores.csv`)

`process_ncsl_results.py`:

Does roughly the same steps as `process_alignment_results.py` but for the ncsl
resutls. Differences: there are no lucene scores (because all bill dyads are
treated) and the structure of the input file
(`data/alignments_new/ncsl_pair_alignments.json`) is slightly different (see the if
condition in the iterator of `AlignmentMatchText()` in
`process_alignment_results.py`). Produces the following outputs:
* `data/alignments_new/ncsl_pair_alignments.csv`: csv file with the scores
* `data/alignments_new/ncsl_align_text.csv`: csv with alignment match text
* `data/alignments_new/ncsl_adjusted.csv`: Final adjusted scores for further
    analysis

Takes about 1h.
