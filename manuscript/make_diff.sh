# Generate and compile latex diff to verion of the manuscript in
# a commit. Commit SHA (id) to compare to is taken as commandline argument

# Get the old version from the relevant commit 
git checkout $1 text_reuse.tex
# Store it in temporary file
cp text_reuse.tex temp
# Restore the most recent version under the original filename
git checkout HEAD text_reuse.tex
# Make the latex diff
latexdiff temp text_reuse.tex > weekly_diff.tex
# Compile latex
pdflatex weekly_diff.tex
bibtex weekly_diff
pdflatex weekly_diff.tex
pdflatex weekly_diff.tex
# Remove temporary file
rm temp
