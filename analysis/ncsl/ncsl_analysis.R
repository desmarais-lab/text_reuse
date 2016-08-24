library(dplyr)
library(ggplot2)
library(xtable)

# Load the data (data preprocessing in `/etl/make_analysis_datasets.R`)
load('../../data/ncsl_analysis/ncsl_analysis.RData')

# Precision recall curve
# ==============================================================================

r <- range(df$score, na.rm = TRUE)
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
    #scale_x_log10(breaks = c(0, 1, 10, 100)) +
    scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1, 1.25)) +
    geom_hline(aes(yintercept = 1), linetype = 2, alpha = 0.2) +
    scale_color_manual(values = cbPalette, 
                       labels = c("Precision", "Recall"),
                       name = "") +
    scale_linetype_manual(values = c(1, 3), 
                       labels = c("Precision", "Recall"),
                       name = "") +
    xlab("Score Threshold") + ylab("Precision / Recall") +
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