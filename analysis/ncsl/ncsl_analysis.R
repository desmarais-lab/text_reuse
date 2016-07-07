library(dplyr)
library(ggplot2)
library(xtable)

# Load and preprocess data
# ==============================================================================

# Load ncsl_analysis.RData to skip processing (takes a long time)

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
bill_pairs <- left_join(df, alignments, 
                        by = c("left_doc_id", "right_doc_id"))
df <- mutate(bill_pairs, alignment_score_NA = ifelse(is.na(alignment_score), 
                                                        1, 0))
rm(bill_pairs)

## Put zero for NA alignment score
df$alignment_score_nona <- ifelse(is.na(df$alignment_score), 0.0001,
                                          df$alignment_score)

# Numbers for the ncsl section in the paper
# ==============================================================================

# Frequency of scores higher 50 / 100
sum(alignments$alignment_score > 50) / nrow(alignments)
sum(alignments$alignment_score > 100) / nrow(alignments)

# Complete Frequency distribution
r <- range(alignments$alignment_score)
thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))

hm <- function(threshold) sum(alignments$alignment_score < threshold) / nrow(alignments)
cumdist <- sapply(thresholds, hm)
pdat <- tbl_df(data.frame("Proportion" = cumdist, "Score" = thresholds))

# Load commont theme elements for plots
source('../plot_theme.R')

ggplot(pdat) + 
    geom_line(aes(x = Score, y = Proportion), size = 1.2) + 
    scale_x_log10(breaks = c(1, 10, 100, 1000, 10000)) + 
    xlab("X") +
    ylab("P(Score < X)") +
    plot_theme
ggsave('../../manuscript/figures/alignment_score_distribution.png', width = p_width, 
       height = 0.65 * p_width)


# Proportion in same table
sum(df$same_table) / nrow(alignments)

# Store the data
save(x = df, file = '../../data/ncsl_analysis/ncsl_analysis.RData')
load('../../data/ncsl_analysis/ncsl_analysis.RData')


# Precision recall curve
# ==============================================================================

r <- range(df$alignment_score_nona, na.rm = TRUE)
thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))

score = df$alignment_score_nona
true = df$same_table

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

df_1 <- data.frame(value = c(prec_rec[, 1], prec_rec[, 2]),
                 threshold = rep(c(thresholds), 2),
                 type = rep(c("precision", "recall"), each = nrow(prec_rec)))


ggplot(df_1) + 
    geom_density(aes(x = alignment_score_nona, y = ..scaled..), data = df, fill = "black",
                 alpha = 0.05, color = "white") +
    geom_line(aes(y = value, x = threshold, color = type, linetype = type),
              size = 1.2) + 
    scale_x_log10() +
    scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1, 1.25)) +
    geom_hline(aes(yintercept = 1), linetype = 2, alpha = 0.2) +
    scale_color_manual(values = cbPalette, 
                       labels = c("Precision", "Recall"),
                       name = "") +
    scale_linetype_manual(values = c(1, 3), 
                       labels = c("Precision", "Recall"),
                       name = "") +
    xlab("Log Score Threshold") + ylab("Precision / Recall") +
    plot_theme

ggsave('../../manuscript/figures/ncsl_prec_rec.png', width = p_width, 
       height = 0.65 * p_width)


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


