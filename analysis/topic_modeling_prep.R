# Set my working directory
setwd("/Users/bdesmarais/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/data/lid/")

# Note, the line below need only be run once, to split the big CSV into smaller files, sending to command line
# pipe("split -l 100000 bill_to_bill_alignments.csv","r")

# Read in sample of data on which to base variable names
sample_dat <- read.csv("bill_to_bill_alignments.csv",nrows=10,stringsAsFactors=F)

# Iteratively read in 100,000 rows at a time to build adjacency matrices
## all of the split files begin with x
files <- dir()
files <- files[which(substr(files,1,1)=="x")]

library(mallet)

aligned_text <- NULL
filenames <- NULL

# loop over files
for(i in 1:length(files)){	
  ## read in 100k rows
  align_dati <- read.csv(files[i],stringsAsFactors=F,header=ifelse(i==1,T,F))
  ## make sure variables have the right names
  names(align_dati) <- names(sample_dat)
  
  filenames <- c(filenames,paste("~/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/data/alignment_files/all_alignments/",align_dati$left_doc_id,align_dati$right_doc_id,align_dati$alignment_section_index,".txt",sep=""))
  
  aligned_text <- c(aligned_text,align_dati$left_alignment_text)
  
  if(i/5==round(i/5)) print(i)
  
  }
 
save(list=c("filenames","aligned_text"),file="~/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/analysis/text_for_mallet.RData")

  mallet.instances <- mallet.import(filenames[1:100000],aligned_text[1:100000],"~/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/analysis/en.txt")


	topic.model <- MalletLDA(num.topics=20)
	
	topic.model$loadDocuments(mallet.instances)
	
	vocabulary <- topic.model$getVocabulary()
	word.freqs <- mallet.word.freqs(topic.model)

	topic.model$setAlphaOptimization(20, 50)
	
	topic.model$maximize(10)
	
	doc.topics <- mallet.doc.topics(topic.model, smoothed=T, normalized=T)
	topic.words <- mallet.topic.words(topic.model, smoothed=T, normalized=T)

	mallet.top.words(topic.model, topic.words[7,])


