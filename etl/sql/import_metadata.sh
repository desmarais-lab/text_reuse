Rscript prep_meta.R
psql -U flinder -d text_reuse -f import_metadata.sql
rm metadata.csv
