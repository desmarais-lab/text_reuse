# Set my working directory
setwd("~/dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/data/lid/")

# Note, the line below need only be run once, to split the big CSV into smaller files, sending to command line
# pipe("split -l 100000 bill_to_bill_alignments.csv","r")

# Read in sample of data on which to base variable names
sample_dat <- read.csv("bill_to_bill_alignments.csv",nrows=10,stringsAsFactors=F)

# Read in complete dyadic dataset from APSR 
state_diffusion_edges <- read.csv("~/dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/data/apsr_replication_files/dhb2015apsr-networks.csv",stringsAsFactors=F)

# Create empty adjacency matrix in which to store alignment scores
## unique state names
ustates <- sort(unique(tolower(state_diffusion_edges$state_01)))
## correctly sized empty matrix
align_amat <- matrix(0,length(ustates),length(ustates))
align_amat_score <- matrix(0,length(ustates),length(ustates))
align_amat_threshold <- matrix(0,length(ustates),length(ustates))
nbills_amat <- matrix(0,length(ustates),length(ustates))
## row names
rownames(align_amat) <- colnames(align_amat) <- ustates
rownames(align_amat_score) <- colnames(align_amat_score) <- ustates
rownames(align_amat_threshold) <- colnames(align_amat_threshold) <- ustates
rownames(nbills_amat) <- colnames(nbills_amat) <- ustates

left_doc <- NULL
right_doc <- NULL

# Iteratively read in 100,000 rows at a time to build adjacency matrices
## all of the split files begin with x
files <- dir()
files <- files[which(substr(files,1,1)=="x")]

nwords <- function(text_vector){
	nw <- unlist(lapply(strsplit(text_vector," "),"length"))
	nw
}

# loop over files
for(i in 1:length(files)){
  ## read in 100k rows
  align_dati <- read.csv(files[i],stringsAsFactors=F,header=ifelse(i==1,T,F))
  ## make sure variables have the right names
  names(align_dati) <- names(sample_dat)
  ## extract state ids from bill labels
  state1 <- substr(align_dati$left_doc_id,1,2)
  state2 <- substr(align_dati$right_doc_id,1,2)
  ## subset to actual states (i.e., exclude dc and any other non-state jurisdictions)
  align_dati <- subset(align_dati,is.element(state1,ustates) & is.element(state2,ustates) & state1 != state2)
  ## extract state ids from subsetted dataset
  state1 <- substr(align_dati$left_doc_id,1,2)
  state2 <- substr(align_dati$right_doc_id,1,2)
  left_doc <- c(left_doc,align_dati$left_doc_id)
  right_doc <- c(right_doc,align_dati$right_doc_id)
  ## create the weight according to which each alignment will contribute
  alignment_score <- align_dati$alignment_score
  ## add in the weight
  for(j in 1:length(alignment_score)){
    align_amat[cbind(state1[j],state2[j])] <- align_amat[cbind(state1[j],state2[j])] + 1
    align_amat[cbind(state2[j],state1[j])] <- align_amat[cbind(state2[j],state1[j])] + 1
    align_amat_score[cbind(state1[j],state2[j])] <- align_amat_score[cbind(state1[j],state2[j])] + log(alignment_score[j]) 
    align_amat_score[cbind(state2[j],state1[j])] <- align_amat_score[cbind(state2[j],state1[j])] + log(alignment_score[j]) 
  }
  ## print to assess timing
  if(i/5==round(i/5)){
    print(i)
  }
}

# number of bills in each state
all_bills <- unique(c(left_doc,right_doc))
bill_states <- substr(all_bills,1,2)
nbills <- numeric(length(ustates))
for(i in 1:length(ustates)){
	nbills[i] <- length(which(bill_states==ustates[i]))
}

nbills_cov <- matrix(0,length(nbills),length(nbills))
for(i in 2:length(nbills)){
	for(j in 1:(i-1)){
		nbills_cov[i,j] <- nbills_cov[j,i] <- nbills[i]*nbills[j]
	}
}


# subset to 2008 edges
state_diffusion_edges2008 <- subset(state_diffusion_edges,year==2008)

# create diffusion adjacency matrix
diff_amat <- matrix(0,length(ustates),length(ustates))
# assure the nodes are consistent
rownames(diff_amat) <- colnames(diff_amat) <- ustates
# add in ties
diff_amat[cbind(tolower(state_diffusion_edges2008$state_01),tolower(state_diffusion_edges2008$state_02))] <- state_diffusion_edges2008$src_35_300
# make sure it is undirected
diff_amat <- diff_amat + t(diff_amat)

# load sna, for qap
library(sna)
# zero out diagonals (i.e., not modeling loops)
diag(diff_amat) <- 0
diag(align_amat) <- 0
# Run ols with qap uncertainty
set.seed(5)
bivariate_qap <- netlm(align_amat_score,diff_amat,mode="graph",reps=5000)
results <- cbind(bivariate_qap$coefficients,bivariate_qap$pgreqabs)
rownames(results) <- c("Intercept","Diffusion Tie")
colnames(results) <- c("Coefficient","p-value")

set.seed(5)
bivariate_qap_log <- netlm(log(align_amat_score),diff_amat,mode="graph",reps=5000)
results_log <- cbind(bivariate_qap_log$coefficients,bivariate_qap_log$pgreqabs)
rownames(results_log) <- c("Intercept","Diffusion Tie")
colnames(results_log) <- c("Coefficient","p-value")

## Prepare results for table
library(xtable)
results_all <- cbind(results,results_log)
xtable(results_all,dig=4)

# boxplots 
x <- diff_amat[lower.tri(diff_amat)]
y <- log(align_amat_score)[lower.tri(align_amat_score)]


## Descriptive statistics
diag(align_amat) <- NA
median(align_amat,na.rm=T)
mean(align_amat,na.rm=T)
sd(align_amat,na.rm=T)

save(list=c("align_amat_score","diff_amat"),file="diffusion_and_reuse_nets.RData")

