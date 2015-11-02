# Set my working directory
setwd("/Users/bdesmarais/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/data/lid/")

# Note, the line below need only be run once, to split the big CSV into smaller files, sending to command line
# pipe("split -l 100000 bill_to_bill_alignments.csv","r")

# Read in sample of data on which to base variable names
sample_dat <- read.csv("bill_to_bill_alignments.csv",nrows=10,stringsAsFactors=F)

# Read in complete dyadic dataset from APSR 
state_diffusion_edges <- read.csv("/Users/bdesmarais/Dropbox/professional/Research/Active/Diffusion_Networks/text_reuse/data/apsr_replication_files/dhb2015apsr-networks.csv",stringsAsFactors=F)

# Create empty adjacency matrix in which to store alignment scores
## unique state names
ustates <- sort(unique(tolower(state_diffusion_edges$state_01)))
## correctly sized empty matrix
align_amat <- matrix(0,length(ustates),length(ustates))
## row names
rownames(align_amat) <- colnames(align_amat) <- ustates

# Iteratively read in 100,000 rows at a time to build adjacency matrices
## all of the split files begin with x
files <- dir()
files <- files[which(substr(files,1,1)=="x")]

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
  align_dati <- subset(align_dati,is.element(state1,ustates) & is.element(state2,ustates))
  ## extract state ids from subsetted dataset
  state1 <- substr(align_dati$left_doc_id,1,2)
  state2 <- substr(align_dati$right_doc_id,1,2)
  ## create the weight according to which each alignment will contribute
  alignment_weight <- 1
  ## add in the weight
  align_amat[cbind(state1,state2)] <- align_amat[cbind(state1,state2)] + alignment_weight 
  align_amat[cbind(state2,state1)] <- align_amat[cbind(state2,state1)] + alignment_weight
  ## print to assess timing
  if(i/5==round(i/5)) print(i)
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
bivariate_qap <- netlm(align_amat,diff_amat,mode="graph",reps=10000)

results <- cbind(bivariate_qap$coefficients,bivariate_qap$pgreqabs)
library(xtable)
rownames(results) <- c("Intercept","Diffusion Tie")
colnames(results) <- c("Coefficient","p-value")
xtable(results,dig=4)
