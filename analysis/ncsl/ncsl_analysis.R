library(dplyr)
library(ggplot2)
library(xtable)

source('../plot_theme.R')

# Load and preprocess data
alignments <- tbl_df(read.csv('../../data/lid/alignments_1000_b2b_ns.csv',
                              stringsAsFactors = FALSE, header = TRUE))
ncsl_bills <- tbl_df(read.csv('../../data/ncsl/ncsl_data_from_sample_matched.csv',
                              stringsAsFactors = FALSE, header = TRUE)) %>% 
    filter(!is.na(matched_from_db)) %>%
    select(-description, -table) 


# Data Frame of all pairs we have table information of (with the matched db ids)
bill_pairs <- tbl_df(as.data.frame(t(combn(ncsl_bills$matched_from_db, 2))))
colnames(bill_pairs) <- c("left_doc_id", "right_doc_id") 
# Also use the reversed combinations
reverse <- data.frame("left_doc_id" = bill_pairs$right_doc_id,
                      "right_doc_id" = bill_pairs$left_doc_id)
bill_pairs <- tbl_df(rbind(bill_pairs, reverse))

# Remove pairs from same state
# incl <- substr(as.character(bill_pairs$left_doc_id), 1, 2) != 
#     substr(as.character(bill_pairs$right_doc_id), 1, 2)
# bill_pairs <- bill_pairs[incl, ]


# Get 'same-table-indicator'
## Join with topic tables
temp <- mutate(ncsl_bills, left_doc_id = matched_from_db, left_table = topic) %>%
    select(left_doc_id, left_table)
df <- left_join(bill_pairs, temp, by = "left_doc_id")
temp <- mutate(ncsl_bills, right_doc_id = matched_from_db, right_table = topic) %>%
    select(right_doc_id, right_table)
df <- left_join(df, temp, by = "right_doc_id") %>% 
    mutate(same_table = ifelse(left_table == right_table, 1, 0))

# Join with alignment data
## Calculate bill level alignments
# bill_alignments <- group_by(alignments, left_doc_id, right_doc_id) %>% 
#     summarize(alignment_score_sum = sum(alignment_score))


## Join
bill_pairs <- left_join(df, alignments, 
                        by = c("left_doc_id", "right_doc_id"))

df <- mutate(bill_pairs, alignment_score_NA = ifelse(is.na(alignment_score), 
                                                        1, 0))
eda_tab <- xtabs( ~ same_table + alignment_score_NA, data = df)

sink(file = '../../manuscript/tables/ncsl_crosstab.tex')
xtable(eda_tab, caption = "Crosstable of being in the same table against having 
       an alignment score for all bill dyads in the ncsl dataset.", 
       label = "tab:ncsl_crosstab")
sink()

#ggplot(df) + 
#    geom_point(aes(x = same_table, y = alignment_score_zeros), 
#               position = "jitter", alpha = 0.6, size = 0.4) +
#    scale_y_log10()


# Precision recall curve

## Put zero for NA alignment score
bill_pairs$alignment_score_nona <- ifelse(is.na(bill_pairs$alignment_score), 0,
                                          bill_pairs$alignment_score)


thresholds <- sort(unique(bill_pairs$alignment_score_nona))
#thresholds <- thresholds[-length(thresholds)]
thresholds <- seq(min(thresholds), max(thresholds), length.out = 200)

#thresholds <- seq(0, 600, length.out = 100)

# Precision recall curve
score = bill_pairs$alignment_score_nona
true = bill_pairs$same_table

pr <- function(threshold) {
    predicted <- ifelse(score >= threshold, 1, 0)
    p <- length(which(predicted == 1))
    tp <- length(which(predicted == 1 & true == 1))
    precision <- tp / p 
    fn <- length(which(predicted == 0 & true == 1))  
    recall <- tp / (tp + fn) 
    return(c(precision, recall))
}

prec_rec <- t(sapply(thresholds, pr))
#prec_rec <- rbind(c(0.09058045, 1), prec_rec) # When threshold 0
df <- data.frame(value = c(prec_rec[, 1], prec_rec[, 2]),
                 threshold = rep(c(thresholds), 2),
                 type = rep(c("precision", "recall"), each = nrow(prec_rec)))

ggplot(df) + 
    geom_line(aes(y = value, x = threshold, color = type)) + 
    scale_color_manual(values = cbPalette[-1]) +
    xlab("Score threshold") + ylab("Value") + labs(color = "") +
    plot_theme
    
    #facet_wrap(~ type, scales = "free")
ggsave('../../manuscript/figures/ncsl_prec_rec.png')


# F1 score
f1 <- prec_rec[, 1] * prec_rec[ , 2] / (prec_rec[, 1] + prec_rec[ ,2])
df1 <- data.frame("f1_score" = f1, "threshold" = thresholds)

ggplot(df1) + 
    geom_line(aes(x = thresholds, y = f1_score))

# Distributions of alignment scores in same table and not same table
score_st <- filter(bill_pairs, same_table==1 & !is.na(alignment_score)) %>% select(alignment_score)
score_st <- score_st$alignment_score

score_nst <- filter(bill_pairs, same_table==0 & !is.na(alignment_score)) %>% select(alignment_score)
score_nst <- score_nst$alignment_score

df2 <- data.frame(score = c(score_st, score_nst), 
                  group = c(rep("same_table", length(score_st)), 
                            rep("not_same_table", length(score_nst))))
ggplot(df2) + 
    geom_histogram(aes(x=score, y=..ncount../sum(..ncount..)), 
                   fill = cbPalette[1], color = "white", bins=30) +
    theme_bw() + facet_wrap(~group, ncol=1) + 
    ylab("Proportion") + xlab("Alignment Score")
ggsave('../../manuscript/figures/align_distri_ncsl_tables.png')
