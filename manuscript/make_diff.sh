# Generate and compile latex diff to verion of the manuscript in
# a commit. Commit SHA (id) to compare to is taken as commandline argument

git checkout $1 text_reuse.tex
cp text_reuse.tex temp
git checkout HEAD text_reuse.tex
latexdiff temp text_reuse.tex > weekly_diff.tex
pdflatex weekly_diff.tex
bibtex weekly_diff
pdflatex weekly_diff.tex
pdflatex weekly_diff.tex
rm temp
