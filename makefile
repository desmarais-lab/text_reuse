ROOT_DIR=/home/flinder/projects/text_reuse
DTA_DIR=$ROOT_DIR/data
ALIGN_DTA=$DTA_DIR/aligner_output
NCSL_DTA=$DTA_DIR/ncsl
IDEO_DTA=%DTA_DIR/ideology_analysis
TABLES=$ROOT_DIR/manuscript/tables
FIGURES=$ROOT_DIR/manuscript/figures

cd $ROOT_DIR

# data files: TODO: exact sources where available
# - extracted_bills_with_sponsors.json from DSSG / sunlight foundation
# - malp_individual.tab (from the malp authors' website) # - legislators.csv (legislators and ids from sunlight foundation matched with #   malp ids (I can't find the original legislator data from sunlight anymore)

# Set up the database
cd etl/database
## Import bill data
_ : $DTA_DIR/initial_data/extracted_bills_with_sponsers.json
	python import_bills.py

## Write metadata to csv file and write bill ids to separate txt file
$DTA_DIR/bill_metadata.csv $DTA_DIR/bill_ids.txt: $DTA_DIR/initial_data/extracted_bills_with_sponsers.json
	python extract_bill_metadata.py

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Generate the alignments
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

## Generate the main alignment dataset

### Get the alignments (this takes about 3 weeks on 120 cores (requries HPC with pbs job scheduler)
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

## Postprocess it (boilerplate weighting) and duplicate removal (yes that's a hack)
$ALIGN_DTA/alignments_notext.csv $ALIGN_DTA/alignments.csv: \
    $ALIGN_DTA/alignments_with_dups.csv
	python process_alignments.py


## Generate the ncsl alignments (full similarity matrix within parent topics
## for all matched bills)

### Steps to generate the ncsl dataset
$NCSL_DTA/checked_urls.csv:
	python etl/ncsl_tables/get_table_urls.py

### Sample from them
$NCSL_DTA/sampled_urls.csv: $NCSL_DTA/checked_urls.csv
	Rscript etl/ncsl_tables/sample_tables.R

### Sampled tables are then processed by hand and stored in 
# $NCSL_DTA/ncsl_data_from_sample.csv

### Get the bills in the ncsl tables that are also in our database
$$NCSL_DTA/ncsl_data_from_sample_matched.csv NCSL_DTA/matched_ncsl_bill_ids.txt: \
    $NCSL_DTA/ncsl_data_from_sample.csv $DTA_DIR/bill_metadata.csv \
    $NCSL_DTA/states.csv
	Rscript etl/ncsl_tables/match_bills.R

### Generate the alignments
$ALIGN_DTA/ncsl_alignments: $NCSL_DTA/matched_ncsl_bill_ids.txt
	python generate_alignments/ncsl_bill_pairs.py

### Postprocess (boilerplate weighting)
$ALIGN_DTA/ncls_alignments_notext.csv: $ALIGN_DTA/ncls_alignments.csv
	python generate_alignments/process_ncls_alignments.py

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Descriptives
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

## Bill database overview (how many bills per state)
$FIGURES/year_count_by_state.png: data/bill_ids.txt data/bill_metadata.csv
	Rscript analysis/exploratory/bill_meta_exp.R

## Exploration of alignment data
$FIGURES/alignment_score_distribution.png $TABLES/alignments_descriptives.yml: \
    $ALIGN_DTA/alignments_notext.csv
	Rscript analysis/exploratory/alignment_exploration.R

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Analysis
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## NCSL

### Generate the cosine similarity scores
### Requires elastic search connection
$NCSL_DTA/cosine_similarities.csv: $NCSL_DTA/matched_ncsl_bill_ids.txt
	python etl/ncsl_cosim/ncsl_cosim.py

### Figures and tables
$FIGURES/ncsl_pr_cosm.png $FIGURES/ncsl_pr_nosplit.png \
    $TABLES/ncsl_auc.tex $TABLES/ncsl_bs_reg.tex $TABLES/prec_rec_distri.txt: \
    $ALIGN_DTA/ncsl_alignments_notext.csv \
    $NCSL_DTA/ncsl_data_from_sample_matched.csv \
    $NCSL_DTA/cosine_similarities.csv
	Rscript analysis/ncsl/ncsl_analysis.R


## Ideology

### Prep dataset
$DTA_DIR/ideology_analysis/ideology_analysis_input.RData: $ALIGN_DTA/alignments_notext.csv \
    $DTA_DIR/bill_metadata.csv
	Rscript analysis/ideology/make_ideology_dataset.R

### Run the bootstrapped regressions (requries HPC with pbs job scheduler)
$IDEO_DIR/regression_results.RData: $IDEO_DIR/ideology_analysis_input.RData
	python analysis/ideology/gen_bs_jobs.py base # Submits base model job
	python analysis/ideology/gen_bs_jobs.py all # Submits bootstrap jobs
	Rscript analysis/ideology/ideology_regression.R	 # Collects outputs

## Diffusion analysis	
$TABLES/diffusion_regression_results.tex: $ALIGN_DTA/alignments_notext.csv \
    $DTA_DIR/bill_metadata.csv $DTA_DIR/dhb2015apsr-networks.csv
	Rscript analysis/diffusion/diffusion_analysis.R

## Parisanship application
$TABLES/partisanship_dyad_distribution.tex $FIGURES/partisanship_score_distribution.png: $DTA_DIR/ideology_analysis/ideology_analysis_input.RData
	Rscript analysis/partisanship/partisanship.R

## Additional stuff for new faces presentation

## Most common alignments
all_alignments.p: $ALIGN_DTA/alignments.csv
	python analysis/exploratory/common_alignments.py

## Proportion aligned distribution
## in alignment_exploration.R 

## import alignments to sql database
_ : $ALIGN_DTA/alignments_notext.csv $ALIGN_DTA/alignments.csv:
	psql -U flinder -d text_reuse -f etl/sql/import_alignments.sql

