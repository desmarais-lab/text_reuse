library(dplyr)
library(network)
library(ggplot2)

# Load and preprocess data
alignments <- tbl_df(read.csv('../../data/lid/bill_to_bill_scores_only.csv',
                              stringsAsFactors = FALSE, header = TRUE))
ncsl_bills <- tbl_df(read.csv('../../data/ncsl/ncsl_data_from_sample_matched.csv',
                              stringsAsFactors = FALSE, header = TRUE)) %>% 
    filter(!is.na(matched_from_db)) %>%
    select(-description, -table) 


# Data Frame of all pairs we have table information of (with the matched db ids)
bill_pairs <- tbl_df(as.data.frame(t(combn(ncsl_bills$matched_from_db, 2))))
colnames(bill_pairs) <- c("left_doc_id", "right_doc_id") 


# Get 'same-table-indicator'
## Join with topic tables
temp <- mutate(ncsl_bills, left_doc_id = matched_from_db, left_table = topic) %>%
    select(left_doc_id, left_table)
df <- left_join(bill_pairs, temp, by = "left_doc_id")
temp <- mutate(ncsl_bills, right_doc_id = matched_from_db, right_table = topic) %>%
    select(right_doc_id, right_table)
df <- left_join(df, temp, by = "right_doc_id") %>% 
    mutate(same_table = ifelse(left_table == right_table, 1, 0))
rm(temp)
gc()


# Join with alignment data
## Calculate bill level alignments
bill_alignments <- group_by(alignments, left_doc_id, right_doc_id) %>% 
    summarize(alignment_score_sum = sum(alignment_score))

## Join
bill_pairs <- left_join(df, alignments, 
                        by = c("left_doc_id", "right_doc_id"))
rm(df)
gc()

df <- mutate(bill_pairs, alignment_score_zeros = ifelse(is.na(alignment_score), 
                                                        0, alignment_score))

# Exclue one big outlier
df <- df[-which.max(df$alignment_score), ]

ggplot(df) + 
    geom_point(aes(x = same_table, y = alignment_score_zeros), 
               position = "jitter", alpha = 0.6, size = 0.4) +
    scale_y_log10()
