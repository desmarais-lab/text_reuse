setwd("/Users/bdesmarais/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/analysis/analysis")
load("text_for_mallet.RData")
load("topic_model_results.RData")

options( java.parameters = "-Xmx4g" )

library(mallet)


# top 100 words
topwords <- as.character(word.freqs$words[order(-word.freqs$term.freq)[1:100]]) 
topWordMat <- matrix(topwords,10,10,byrow=T)
library(xtable)
xtable(topWordMat)

topwords_c <- paste(topwords,collapse = " ")

# get alignment length
align_length <- nchar(aligned_text)

topic_top_words <- NULL
for(i in 1:nrow(topic.words)){
	top_wordsi <- order(-topic.words[i,])[1:10]
	top_wordsi <- vocabulary[top_wordsi]
	top_wordsi <- paste(top_wordsi,collapse=" ")
	topic_top_words <- c(topic_top_words,top_wordsi)
}

topic_top_words <- cbind(topic_top_words[order(-topic.probs)])
row.names(topic_top_words) <- order(-topic.probs)
xtable(topic_top_words)

# Alignments on Topic 17
biggest17 <- order(-doc.topics[,17])[1:10]
aligned_text[biggest17]


