# Alignment Generation



There are two alignment generation processes, one for the general database using
the elastic search preselection and one for the bills we have ncsl table
information on and where we calculate the full dyadic dataset.

## NCSL alignments

* Main script: `ncsl_bill_pairs.py`
* Input: `../data/ncsl/matched_ncsl_bill_ids.txt` contains a list of all bills
    that have been matched between the database and the ncsl table sample. 
* Output: `../data/alignments_new/ncsl_pair_alignments.json`

## General alignments
