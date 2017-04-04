# ETL for alignment output


This directory contains scripts to process the big json output from the
alignment algorithm.

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
