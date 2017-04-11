library(dplyr)

# Read in the alignment data and aggregate to state dyad level
fast_read <- function(filename) {
    samp <- read.table(filename, header = TRUE, nrows = 2, 
                       stringsAsFactors = FALSE, sep = ',')
    classes <- sapply(samp, class)
    return(read.table(filename, header = TRUE, colClasses = classes,
                      stringsAsFactors = FALSE, sep = ',', 
                      comment.char = ""))
}

ifile <- '../../data/aligner_output/alignments_notext.csv'
alignments <- tbl_df(fast_read(ifile)) %>%
    mutate(left_state = sapply(strsplit(left_id, "_"), function(x) x[1]),
           right_state = sapply(strsplit(right_id, "_"), function(x) x[1])) %>%
    select(-left_id, -right_id, -lucene_score, -max_lucene_score) %>%
    group_by(left_state, right_state) %>%
    summarize(sum_score = sum(adjusted_alignment_score),
              mean_score = mean(adjusted_alignment_score),
              median_score = median(adjusted_alignment_score))
write.csv('../../data/state_dyad_alignments.csv', row.names = FALSE)
alignments <- read.csv('../../data/state_dyad_alignments.csv', 
                       stringsAsFactors = FALSE)

# Read in complete dyadic dataset from APSR 
state_diffusion_edges <- read.csv("../../data/diffusion/dhb2015apsr-networks.csv", 
                                  stringsAsFactors=F)

# subset to 2008 edges
state_diffusion_edges2008 <- subset(state_diffusion_edges,year==2008)

# Get coverage by state
state_coverage <- tbl_df(read.csv('../../data/bill_metadata.csv',
                                  stringsAsFactors = FALSE)) %>%
    select(unique_id, state) %>%
    group_by(state) %>%
    summarize()
    
state_coverage <- read.csv("../../data/nbills_by_state.csv",stringsAsFactors=F)

ustates <- sort(unique(c(alignments$left_state,alignments$right_state)))
ustates <- ustates[which(!is.element(ustates,c("pr","dc")))]

# removing pr and dc
alignments <- subset(alignments,alignments$left_state != "dc" & alignments$right_state != "dc")
alignments <- subset(alignments,alignments$left_state != "pr" & alignments$right_state != "pr") 

# create diffusion adjacency matrix
diff_amat <- matrix(0,length(ustates),length(ustates))
# assure the nodes are consistent
rownames(diff_amat) <- colnames(diff_amat) <- ustates
# add in ties
diff_amat[cbind(tolower(state_diffusion_edges2008$state_01),tolower(state_diffusion_edges2008$state_02))] <- state_diffusion_edges2008$src_35_300
# make sure it is undirected
diff_amat <- diff_amat + t(diff_amat) 
diff_amat <- 1*(diff_amat>0)

# alignment amat
align_amat <- matrix(0,length(ustates),length(ustates))
# assure the nodes are consistent
rownames(align_amat) <- colnames(align_amat) <- ustates
# add in ties
align_amat[cbind(tolower(alignments$left_state),tolower(alignments$right_state))] <- alignments$sum_score
# make sure it is undirected
align_amat <- align_amat + t(align_amat)

# years covered
yrs_covered <- numeric(length(ustates))
coverage <- table(subset(state_coverage$state,!is.element(state_coverage$state,c("pr","dc"))))
yrs_covered[match(names(coverage),ustates)] <- coverage
coverage_mat <- log(cbind(yrs_covered)%*%t(yrs_covered))

# load sna, for qap
library(sna)
# zero out diagonals (i.e., not modeling loops)
diag(diff_amat) <- 0
diag(align_amat) <- 0
diag(coverage_mat) <- 0
# Run ols with qap uncertainty
set.seed(5)
bivariate_qap <- netlm(align_amat,list(diff_amat,coverage_mat),mode="graph",reps=5000)
results <- cbind(bivariate_qap$coefficients / sd(alignments$sum_score),
                 bivariate_qap$pgreq)
rownames(results) <- c("Intercept","Diffusion Tie","Coverage")
colnames(results) <- c("Coefficient","p-value")

set.seed(5)
bivariate_qap_log <- netlm(log(align_amat),list(diff_amat,coverage_mat),mode="graph",reps=5000)
results_log <- cbind(bivariate_qap_log$coefficients / sd(log(alignments$sum_score)),
                     bivariate_qap_log$pgreq)
rownames(results_log) <- c("Intercept","Diffusion Tie","Coverage")
colnames(results_log) <- c("Coefficient","p-value")

## Prepare results for table
library(xtable)
results_all <- cbind(results,results_log)
xtable(results_all,dig=3)

# boxplots
x <- diff_amat[lower.tri(diff_amat)]
y <- log(align_amat)[lower.tri(align_amat)]

## Descriptive statistics
diag(align_amat) <- NA
median(align_amat,na.rm=T)
mean(align_amat,na.rm=T)
sd(align_amat,na.rm=T)

save(list=c("align_amat_score","diff_amat"),file="diffusion_and_reuse_nets.RData")


