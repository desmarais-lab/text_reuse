ROOT_DIR=/home/flinder/projects/text_reuse
DTA_DIR=$ROOT_DIR/data
ALIGN_DTA=$DTA_DIR/aligner_output
NCSL_DTA=$DTA_DIR/ncsl
TABLES=$ROOT_DIR/manuscript/tables
FIGURES=$ROOT_DIR/manuscript/figures

cd $ROOT_DIR

# data files: TODO: exact sources where available
# - extracted_bills_with_sponsors.json from DSSG / sunlight foundation
# - malp_individual.tab (from the malp authors' website)
# - legislators.csv (legislators and ids from sunlight foundation matched with 
#   malp ids (I can't find the original legislator data from sunlight anymore)

# Set up the database

## Import bills
_ : $DTA_DIR/initial_data/extracted_bills_with_sponsers.json
	python import_bills.py

## Write metadata to csv file and write bill ids to separate txt file
$DTA_DIR/bill_metadata.csv $DTA_DIR/bill_ids.txt: $DTA_DIR/initial_data/extracted_bills_with_sponsers.json
	python extract_bill_metadata.py

# Generate the alignments

## Generate the main alignment dataset

### Get the alignments (this takes about 3 weeks on 120 cores)
$ALIGN_DTA/alignments.csv: $DTA_DIR/bill_ids.txt
	# All these three can be run in parallel:
	# Generates the actual alignments
	python generate_alignments/run_hpc.py
	# Collects the output files from each job and writes them to main output
	# files
	python generate_alignments/process_results.py $ALIGN_DTA/alignments \
	    $ALIGN_DTA/alignments.csv
	python generate_alignments/process_results.py $ALIGN_DTA/bill_status \
	    $ALIGN_DTA/bill_status.csv

## Postprocess it (boilerplate weighting)
$ALIGN_DTA/alignments_notext.csv: $ALIGN_DTA/alignments.csv
	python process_alignments.py

## Generate the ncsl alignments (full similarity matrix for all matched bills)

### TODO: fill in steps to generate the ncsl dataset

### Get the bills in the ncsl tables that are also in our database
$NCSL_DTA/matched_ncsl_bill_ids.txt: $NCSL_DTA/ncsl_data_from_sample.csv $DTA_DIR/bill_metadata.csv 
	Rscript etl/ncsl_tables/match_bills.R

### Generate the alignments
$ALIGN_DTA/ncsl_alignments: $NCSL_DTA/matched_ncsl_bill_ids.txt
	python generate_alignments/ncsl_bill_pairs.py


### Postprocess (boilerplate weighting)
$ALIGN_DTA/ncls_alignments_notext.csv: $ALIGN_DTA/ncls_alignments.csv
	python generate_alignments/process_ncls_alignments.py




# Descriptives

## Bill database overview (how many bills per state)
$FIGURES/year_count_by_state.png: data/bill_ids.txt data/bill_metadata.csv
	Rscript analysis/exploratory/bill_meta_exp.R

## Exploration of alignment data
$FIGURES/alignment_score_distribution.png $TABLES/alignments_descriptives.yml: \
    $ALIGN_DTA/alignments_notext.csv
	analysis/exploratory/alignment_exploration.R


# Analysis
