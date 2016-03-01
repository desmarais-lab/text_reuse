library(dplyr)
library(ggplot2)

# Metadata
meta <- read.csv('../../data/bill_metadata.csv', stringsAsFactors = FALSE,
                 header = TRUE, quote = '"')

## Clean it up

### Make 'None' NA
meta[meta == 'None'] <- NA
### Fix column classes
for(i in grep("date_", names(meta))){
    var <- sapply(as.character(meta[, i]), substr, 1, 10)
    var
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

# Alignments
alignments <- tbl_df(read.csv('../../data/lid/bill_to_bill_scores_only.csv', 
                              header = TRUE, stringsAsFactors = FALSE))

## Match alignments with introduction time and document length
### Join info on left bill
temp <- mutate(meta, left_doc_id = unique_id, 
               left_date_introduced = date_introduced) %>%
    dplyr::select(left_doc_id, left_date_introduced)
df <- left_join(alignments, temp, by = "left_doc_id")

### Join info on right bill
temp <- mutate(meta, right_doc_id = unique_id, 
               right_date_introduced = date_introduced) %>%
    dplyr::select(right_doc_id, right_date_introduced)
df <- left_join(df, temp, by = "right_doc_id")

# Calculate time difference
df <- mutate(df, 
             time_diff = abs(as.integer(left_date_introduced - 
                                            right_date_introduced)),
             dyad_id = as.factor(paste0(left_doc_id, right_doc_id)))

# Aggregate to bill level
aggr <- group_by(df, left_doc_id, right_doc_id) %>%
    summarize(sum_score = sum(alignment_score), 
              time_diff = time_diff[1])  
rm(alignments)
gc()

# Descriptives for the time diff
ggplot(aggr) + 
    geom_histogram(aes(x = time_diff), color = "white", binwidth = 300) + 
    theme_bw()

tab <- table(aggr$time_diff)
cumu_time_diff = data.frame(cumu = cumsum(tab),
                            days = as.integer(names(tab)))
ggplot(cumu_time_diff) + 
    geom_point(aes(x = days, y = cumu), size = 0.5) +
    ylab("Cumulative number of observations") + 
    xlab("Introduction date difference (days)") +
    theme_bw()
ggsave('../../4344753rddtnd/figures/cumu_date_diff.png')


# Relationship between time diff and sum score
ggplot(aggr) + 
    geom_point(aes(x = time_diff, y = sum_score), size = 0.6, alpha = 0.3) + 
    scale_y_log10() + 
    ylab("Log alignment score (sum)") + 
    xlab("Introduction date difference (days)") +
    theme_bw()
ggsave('../../4344753rddtnd/figures/log_date_diff_score.png')

ggplot(aggr) + 
    geom_point(aes(x = time_diff, y = sum_score), size = 0.6, alpha = 0.3) + 
    ylab("Alignment score (sum)") + 
    xlab("Introduction date difference (days)") +
    theme_bw()
ggsave('../../4344753rddtnd/figures/date_diff_score.png')


# Analysis
source('../ideology/qap.R')

# Prepare objects for the qap procedure
aggr <- as.data.frame(aggr)

## Get ideology scores
time_diff <- dplyr::select(meta, unique_id, date_introduced)
time_diff <- na.omit(as.data.frame(time_diff))

## Generate fast lookup objects

### Generate a mappin: bill_id -> integer_id
n_dyads <- nrow(aggr)
unique_bills <- unique(c(aggr$left_doc_id, 
                         aggr$right_doc_id)) 
n_bills <- length(unique_bills)
ids <- as.list(c(1:n_bills))
names(ids) <- unique_bills
id_map <- list2env(ids, hash = TRUE, size = n_bills)

### store ideology values in same order as integer ids
### for lookup by position 
temp <- as.list(time_diff[, 2])
names(temp) <- time_diff[, 1]
time_map <- list2env(x = temp, hash = TRUE, size = nrow(time_diff))
rm(temp)
time_lookup <- function(bill) get(x = bill, envir = time_map)
time_diffs <- sapply(unique_bills, time_lookup) 

### Generate edgelist with integer ids for alignment network
edges <- matrix(rep(NA, 3 * n_dyads), ncol = 3, nrow = n_dyads)
get_from_envir <- function(i, col, df) {
    get(x = df[i, col], envir = id_map)
}
edges[, 1] <- sapply(c(1:n_dyads), get_from_envir, col = 1, df = aggr)
edges[, 2] <- sapply(c(1:n_dyads), get_from_envir, col = 2, df = aggr)

save.image("qap_data_time_diff.RData")

## Number of qap permutations
n_qap_perm <- 1000
## Number of cores for permutations
n_cores <- 40

## Linear model for sum aggregation (with qap standard errors)
time_diff_mod <- lm(log(sum_score) ~ time_diff, data = aggr)
edges[, 3] <- aggr$sum_score
perm_dist_time_diff <- qap(edges, time_diffs, nperm = n_qap_perm, cores = n_cores)

save(list = c("time_diff_mod", "perm_dist_time_diff"), file = "qap_results_time_diff.RData")
