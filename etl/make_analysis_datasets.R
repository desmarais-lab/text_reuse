library(dplyr)
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
SMALL <- as.logical(args[1])

# Load Alignments and lucene scores
cat("Loading alignment data...\n")

if(SMALL) {
    alignments <- tbl_df(read.csv('../data/lid/alignments_1000_b2b_ns.csv', 
                         header = TRUE, stringsAsFactors = FALSE, nrows = 50000))
    lucene_scores <- tbl_df(read.csv('../data/lid/lucene_scores_1000.csv',            #still contains same-state dyads
                         header = TRUE, stringsAsFactors = FALSE, nrows = 50000))
} else {
    alignments <- tbl_df(read.csv('../data/lid/alignments_1000_b2b_ns.csv', 
                         header = TRUE, stringsAsFactors = FALSE))
    lucene_scores <- tbl_df(read.csv('../data/lid/lucene_scores_1000.csv', 
                         header = TRUE, stringsAsFactors = FALSE))
}

# Merge them and discard lucene
alignments <- left_join(alignments, lucene_scores, by = c("left_doc_id",
                                                          "right_doc_id"))
rm(lucene_scores)
gc()

cat("========================================================================\n")
cat("Descriptive statistics for alignments\n")
cat("========================================================================\n")

# Descriptive stats for alignment dataset
sink('alignments_descriptives.txt')
cat(paste0("Number of bill dyads: ", nrow(alignments), '\n'))
cat(paste0("Mean score: ", mean(alignments$alignment_score), '\n'))
cat(paste0("Median score: ", median(alignments$alignment_score), '\n'))
sink()

# Distribution of alignment scores
r <- range(alignments$alignment_score)
thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))

hm <- function(threshold) sum(alignments$alignment_score < threshold) / nrow(alignments)
cumdist <- sapply(thresholds, hm)
pdat <- tbl_df(data.frame("Proportion" = cumdist, "Score" = thresholds))

# Load commont theme elements for plots
source('../analysis/plot_theme.R')

p <- ggplot(pdat) + 
    geom_line(aes(x = Score, y = Proportion), size = 1.2) + 
    scale_x_log10(breaks = c(1, 10, 100, 1000, 10000)) + 
    xlab("X") +
    ylab("P(Score < X)") +
    plot_theme
ggsave('../manuscript/figures/alignment_score_distribution.png', width = p_width, 
       height = 0.65 * p_width)


# Relationship of alignment and lucene score
p <- ggplot(alignments, aes(x = lucene_score, y = alignment_score)) + 
    stat_binhex(bins = 150) +
    xlab("Lucene Score") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = cbPalette[1], high = cbPalette[2], trans = "log",
                        labels = function (x) round(x, 0)) +
    guides(fill=guide_legend(title="Count")) +
    plot_theme

cat('Saving plot...\n')
ggsave(plot = p, '../manuscript/figures/alignment_lucene.png', 
       width = p_width, height = 0.65 * p_width)


alignments$lucene_score <- NULL

cat("========================================================================\n")
cat("Data preprocessing for ideology analysis\n")
cat("========================================================================\n")


# Load metadata
cat("Loading metadata...\n")
meta <- read.csv('../data/lid/bill_metadata.csv', stringsAsFactors = FALSE,
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


## Match alignments with ideology scores and document length
### Join info on left bill
cat("Joining datasets...\n")
temp <- mutate(meta, left_doc_id = unique_id, left_ideology = sponsor_idology,
               left_length = bill_length) %>%
    dplyr::select(left_doc_id, left_ideology, left_length)
df <- left_join(alignments, temp, by = "left_doc_id")

### Join info on right bill
temp <- mutate(meta, right_doc_id = unique_id, right_ideology = sponsor_idology,
               right_length = bill_length) %>%
    dplyr::select(right_doc_id, right_ideology, right_length)
df <- left_join(df, temp, by = "right_doc_id")

# Calculate ideological distance and combined doc length
df <- mutate(df, ideology_dist = (left_ideology - right_ideology)^2)

cat("Descriptives for ideology data\n")
cat("************************************************************************\n")

# Stats for text
sink('../analysis/ideology/data_desc_stats.txt')
n <- nrow(df)
cat(paste0("Preprocessed data from ", n, " bill dyads.\n"))
df <- filter(df, !is.na(ideology_dist))
m <- nrow(df)
cat(paste0((1 - m / n), "% of dyads missing ideological distance.\n"))
cat(paste0((n - m), " bills don't have ideological distance \n"))
cat(paste0(m, " valid dyads from ", length(unique(df$left_doc_id)), 
           " left bills and ", length(unique(df$right_doc_id)), 
           " right bills remaining.\n"))
sink()


# Save ideology data
fname <- ifelse(SMALL, "../data/ideology_analysis/ideology_small.RData",
       "../data/ideology_analysis/ideology.R")
cat(paste0("Saving to ", fname, "\n"))
save(df, file = fname)


cat("========================================================================\n")
cat("Data preprocessing for ncsl analysis\n")
cat("========================================================================\n")


# Load the ncsl alignment raw data and log scores, aggregate by bill pair
# and remove same state bill pairs
retx <- function(x, i) x[i] 
ncsl_raw <- tbl_df(read.csv('../data/ncsl/ncsl_alignment_scores.csv',
                            stringsAsFactors = FALSE, header = TRUE))%>%
  mutate(old_score = score, score = adj_score) %>%
  select(-adj_score)

ncsl_alignments <- filter(ncsl_raw, !is.na(score)) %>%
    filter(score != 0) %>%
    #mutate(score = log(score), old_score = log(old_score)) %>%
    group_by(left_doc_id, right_doc_id) %>%
    summarize(score = sum(score), count = n(), old_score = sum(old_score)) %>%
    mutate(left_state = sapply(strsplit(left_doc_id, "_"), retx, 1),
           right_state = sapply(strsplit(right_doc_id, "_"), retx, 1),
           old_score = log(old_score),
           score = log(score)) %>%
    filter(left_state != right_state) %>%
    select(-left_state, -right_state)

# Load the ncsl table dataset
ncsl_bills <- tbl_df(read.csv('../data/ncsl/ncsl_data_from_sample_matched.csv',
                              stringsAsFactors = FALSE, header = TRUE)) %>% 
    filter(!is.na(matched_from_db))

# Write out all the ids we could match to database for pairwise alignment computation
sink('../data/ncsl/matched_ncsl_bill_ids.txt')
for(id_ in ncsl_bills$matched_from_db){
    cat(paste0(id_, '\n'))
}

sink()

# Summary table of tables (for poster)
#group_by(ncsl_bills, topic) %>% summarize(count = n())

# Data Frame of all pairs we have table information of (with the matched db ids)
bill_pairs <- tbl_df(as.data.frame(t(combn(ncsl_bills$matched_from_db, 2))))
colnames(bill_pairs) <- c("left_doc_id", "right_doc_id") 
# Also use the reversed combinations
reverse <- data.frame("left_doc_id" = bill_pairs$right_doc_id,
                      "right_doc_id" = bill_pairs$left_doc_id)
bill_pairs <- tbl_df(rbind(bill_pairs, reverse))




# Get 'same-table-indicator'
## Join with topic tables
temp <- mutate(ncsl_bills, left_doc_id = matched_from_db, left_table = topic) %>%
    select(left_doc_id, left_table)
df <- left_join(bill_pairs, temp, by = "left_doc_id")
temp <- mutate(ncsl_bills, right_doc_id = matched_from_db, right_table = topic) %>%
    select(right_doc_id, right_table)
df <- left_join(df, temp, by = "right_doc_id") %>% 
    mutate(same_table = ifelse(left_table == right_table, 1, 0))

## Join
bill_pairs <- left_join(df, ncsl_alignments, 
                        by = c("left_doc_id", "right_doc_id"))
# Sanity check: match with alignmetns from general alignment algo
#bill_pairs <- left_join(df, alignments, 
#                        by = c("left_doc_id", "right_doc_id"))

df <- filter(bill_pairs, !is.na(score)) %>%
    select(-left_table, -right_table)
rm(bill_pairs)


cat("Descriptive stats for ncsl\n")
# ==============================================================================

# Frequency of scores higher 50 / 100
sink('../analysis/ncsl/ncsl_data_descriptives.txt')
cat(paste0('Frequency of scores higher than 50: '), 
    sum(ncsl_alignments$score > 50) / nrow(ncsl_alignments),
    '\n')
cat(paste0('Frequency of scores higher than 100: '), 
    sum(ncsl_alignments$score > 100) / nrow(ncsl_alignments),
    '\n')
cat(paste0('Proportion in same table: '), 
    sum(df$same_table) / nrow(df),
    '\n')

sink()

# Write out the list of ncsl bill ids (lid format)
#out_ids <- unique(df$left_doc_id)
#writeLines(out_ids, con = '../data/ncsl_analysis/ncsl_analysis.')

cat("Store the data\n")
save(x = df, file = '../data/ncsl_analysis/ncsl_analysis.RData')

cat("========================================================================\n")
cat("Data preprocessing for lucene analysis\n")
cat("========================================================================\n")

save(alignments, file = '../data/lucene_analysis/lucene_analysis.RData')


