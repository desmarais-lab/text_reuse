library(dplyr)
library(ggplot2)


load('../../data/lucene_analysis/lucene_analysis.RData')


cor(alignments$alignment_score, alignments$lucene_score)
