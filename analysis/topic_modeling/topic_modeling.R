setwd("/storage/group/bbd5087_collab/text_reuse/analysis")
load("text_for_mallet.RData")

options( java.parameters = "-Xmx80g" )

#install.packages("mallet",lib="/storage/group/bbd5087_collab/r_packages",repos="http://cran.stat.ucla.edu/")

.libPaths("/storage/group/bbd5087_collab/r_packages")

library(mallet)

set.seed(10)

filenamesRS <- filenames
aligned_textRS <- aligned_text

mallet.instances <- mallet.import(filenamesRS,aligned_textRS,"en.txt")

topic.model <- MalletLDA(num.topics=20)
	
topic.model$loadDocuments(mallet.instances)
	
vocabulary <- topic.model$getVocabulary()
word.freqs <- mallet.word.freqs(topic.model)

topic.model$setAlphaOptimization(20, 50)

topic.model$train(300)
	
topic.model$maximize(10)
	
doc.topics <- mallet.doc.topics(topic.model, smoothed=T, normalized=T)
topic.words <- mallet.topic.words(topic.model, smoothed=T, normalized=T)

topic.probs <- apply(doc.topics,2,mean)

mallet.top.words(topic.model, topic.words[6,],20)

save(list=c("topic.model","doc.topics","topic.words","topic.probs","vocabulary","word.freqs"),file="topic_model_results.RData")
