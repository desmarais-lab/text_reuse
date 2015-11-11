load("~/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/analysis/text_for_mallet.RData")

library(mallet)

set.seed(10)
samp.ind <- sample(1:length(filenames),200000,rep=T)

filenamesRS <- filenames[samp.ind]
aligned_textRS <- aligned_text[samp.ind]

mallet.instances <- mallet.import(filenamesRS,aligned_textRS,"~/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/analysis/en.txt")

topic.model <- MalletLDA(num.topics=20)
	
topic.model$loadDocuments(mallet.instances)
	
vocabulary <- topic.model$getVocabulary()
word.freqs <- mallet.word.freqs(topic.model)

topic.model$setAlphaOptimization(20, 50)

topic.model$train(200)
	
topic.model$maximize(10)
	
doc.topics <- mallet.doc.topics(topic.model, smoothed=T, normalized=T)
topic.words <- mallet.topic.words(topic.model, smoothed=T, normalized=T)

topic.probs <- apply(doc.topics,2,mean)

mallet.top.words(topic.model, topic.words[6,],20)


