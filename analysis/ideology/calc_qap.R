library(dplyr)

# Load the alignment data
cat('Loading alignment data...\n')
load("ideology_analysis.RData")
aggr <- filter(aggr, !is.na(ideology_dist))


# Metadata
cat('Loading metadata...\n')
meta <- read.csv('../../data/lid/bill_metadata.csv', stringsAsFactors = FALSE,
                 header = TRUE, quote = '"')

## Clean it up
meta$session <- NULL
### Make 'None' NA
meta[meta == 'None'] <- NA
### Fix column classes
for(i in grep("date_", names(meta))){
    var <- sapply(as.character(meta[, i]), substr, 1, 10)
    meta[, i] <- as.Date(x = var)
}
for(col in c("state", "chamber", "bill_type")){
    meta[, col] <- as.factor(meta[, col])
}
meta$sponsor_idology <- as.numeric(meta$sponsor_idology)
meta$num_sponsors <- as.integer(meta$num_sponsors)
meta$bill_length <- as.integer(meta$bill_length)

## Make dplyr object
meta <- tbl_df(meta)


# QAP
# ==============================================================================
source('qap.R')

if(file.exists('qap_data.RData')) {
    cat('Loading prepared data...\n')
    load('qap_data.RData')
} else {
    cat('Preparing qap objects...\n')
    # Prepare objects for the qap procedure
    print('Preparing qap data')
    aggr <- as.data.frame(aggr)
     
    # Get ideology scores
    ideology <- dplyr::select(meta, unique_id, sponsor_idology)
    ideology <- as.data.frame(ideology)
     
    # Generate fast lookup objects
     
    ## Generate a mappin: bill_id -> integer_id
    n_dyads <- nrow(aggr)
    unique_bills <- unique(c(aggr$left_doc_id, 
                              aggr$right_doc_id)) 
    n_bills <- length(unique_bills)
    ids <- as.list(c(1:n_bills))
    names(ids) <- unique_bills
    id_map <- list2env(ids, hash = TRUE, size = n_bills)
     
    ## store ideology values in same order as integer ids
    ## for lookup by position 
    temp <- as.list(ideology[, 2])
    names(temp) <- ideology[, 1]
    ideo_map <- list2env(x = temp, hash = TRUE, size = nrow(ideology))
    rm(temp)
    ideo_lookup <- function(bill) get(x = bill, envir = ideo_map)
    ideologies <- sapply(unique_bills, ideo_lookup) 
     
    ## Generate edgelist with integer ids for alignment network
    edges <- matrix(rep(NA, 3 * n_dyads), ncol = 3, nrow = n_dyads)
    get_from_envir <- function(i, col, df) {
         get(x = df[i, col], envir = id_map)
    }
    edges[, 1] <- sapply(c(1:n_dyads), get_from_envir, col = 1, df = aggr)
    edges[, 2] <- sapply(c(1:n_dyads), get_from_envir, col = 2, df = aggr)
     
    save.image("qap_data.RData")
}


# If not available uncomment code below
    
## Number of qap permutations
n_qap_perm <- 10
## Number of cores for permutations
n_cores <- 4
 
## Model (with qap standard errors)
print(paste0('Singel model startet at: ', Sys.time()))
mod <- rq(alignment_score ~ ideology_dist, data = aggr, tau = 0.95)
print(paste0('Singel model finished at: ', Sys.time()))

edges[, 3] <- aggr$alignment_score

print(paste0('QAP startet at: ', Sys.time()))
perm_dist_sum <- qap(edges, ideologies, nperm = n_qap_perm, cores = n_cores,
                     mode = "quantile", tau = "0.95")
print(paste0('QAP finished at: ', Sys.time()))

save(list = c("mod", "perm_dist_sum"), file = "qap_results.RData")
