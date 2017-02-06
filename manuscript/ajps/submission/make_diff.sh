# Compiled diff between two versions of a latex document
# Arguments:
#  1: filename
#  2: commit id

cp $1 backup
cp $1 temp
git checkout $2 $1
latexdiff $1 temp > diff.tex
pdflatex diff.tex
bibtex diff
pdflatex diff.tex
pdflatex diff.tex

git checkout HEAD $1
rm temp
rm diff.aux
rm diff.log
rm diff.out
rm diff.tex
rm diff.bbl
rm diff.blg
