library(dplyr)
library(ggplot2)


load('../../data/lucene_analysis/lucene_analysis.RData')

samp <- alignments[sample(c(1:nrow(alignments)), 100000), ]


ggplot(samp) + geom_point(aes(x = lucene_score, y = alignment_score))
