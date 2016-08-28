library(dplyr)
library(ggplot2)
library(xtable)

# Load the data (data preprocessing in `/etl/make_analysis_datasets.R`)
load('../../data/ncsl_analysis/ncsl_analysis.RData')
source('../plot_theme.R')

# Descriptives
# ==============================================================================

# Exclude technical correction bill
df <- filter(df, score != max(score))

# Summary stats
# Adjusted score
group_by(df, same_table) %>% 
    summarize(mean = mean(score),
              median = median(score),
              q25 = quantile(score, 0.25),
              q75 = quantile(score, 0.75),
              stdev = sqrt(var(score)))
# Old score
group_by(df, same_table) %>% 
    summarize(mean = mean(old_score),
              median = median(old_score),
              q25 = quantile(old_score, 0.25),
              q75 = quantile(old_score, 0.75),
              stdev = sqrt(var(old_score)))

# Clustered bootstrap regression model

## Model
mod <- lm(score ~ same_table, data = df)

## Uncertainty using the bootstrap
B <- 1000

clusters <- unique(df$left_doc_id)
nc <- length(clusters)
out <- matrix(rep(NA, B * 2), nc = 2, nr = B)

for(i in 1:B) {
    
    # Sample clusters and build iteration-dataset
    sc <- sample(clusters, nc, replace = TRUE)
    dat <- filter(df, is.element(left_doc_id, sc))
    
    # fit models 
    bs_mod <- lm(score ~ same_table, data = dat)
    coefs <- coef(bs_mod)
    out[i, ] <- coefs
    
    if(i %% 10 == 0){
        print(i)
    }
}

## Interpret


# Difference in means
t.test(df$score[df$same_table == 0], df$score[df$same_table == 1])
t.test(df$old_score[df$same_table == 0], df$old_score[df$same_table == 1])

# Box Plots
ggplot(df) +
    geom_boxplot(aes(x = as.factor(same_table), y = score)) + 
    plot_theme

ggplot(df) +
    geom_boxplot(aes(x = as.factor(same_table), y = old_score)) + 
    plot_theme


ggplot(df) +
    geom_histogram(aes(x = score), color = "white") +
    facet_wrap(~ same_table, ncol = 1) +
    plot_theme

# Alignment examples
align_text <- tbl_df(read.table('../../data/ncsl/unique_alignments.tsv',
                                sep = '\t', stringsAsFactors = FALSE,
                                header = TRUE))
align_text <- align_text[order(align_text$count, decreasing = TRUE), ]

head(as.data.frame(align_text))


# Distribution stats

# Frequency of scores higher 5 / 10
sink('ncsl_data_descriptives.txt')
cat(paste0('Frequency of scores higher than 5: '), 
    sum(df$score > 6) / nrow(df),
    '\n')
cat(paste0('Frequency of scores higher than 7: '), 
    sum(df$score > 8) / nrow(df),
    '\n')
cat(paste0('Proportion in same table: '), 
    sum(df$same_table) / nrow(df),
    '\n')

sink()

# Precision recall curve
# ==============================================================================

pr <- function(threshold) {
    predicted <- ifelse(score >= threshold, 1, 0)
    p <- length(which(predicted == 1))
    tp <- length(which(predicted == 1 & true == 1))
    precision <- tp / p 
    fn <- length(which(predicted == 0 & true == 1))  
    recall <- tp / (tp + fn) 
    return(c(precision, recall))
}

# Adjusted score
r <- range(df$score, na.rm = TRUE)
thresholds <- seq(r[1], r[2], length.out = 100)

score = df$score
true = df$same_table

prec_rec <- t(sapply(thresholds, pr))

df_1 <- data.frame(value = c(prec_rec[, 1], prec_rec[, 2]),
                 threshold = rep(c(thresholds), 2),
                 type = rep(c("precision", "recall"), each = nrow(prec_rec)))


ggplot(df_1) + 
    geom_density(aes(x = score, y = ..scaled..), data = df, fill = "black",
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
    xlab("Log Score Threshold") + ylab("Precision / Recall") +
    plot_theme

ggsave('../../manuscript/figures/ncsl_prec_rec_adj.png', width = p_width, 
       height = 0.65 * p_width)


# Old score
r <- range(df$old_score, na.rm = TRUE)
thresholds <- seq(r[1], r[2], length.out = 100)

score = df$old_score
true = df$same_table

prec_rec <- t(sapply(thresholds, pr))

df_1 <- data.frame(value = c(prec_rec[, 1], prec_rec[, 2]),
                 threshold = rep(c(thresholds), 2),
                 type = rep(c("precision", "recall"), each = nrow(prec_rec)))


ggplot(df_1) + 
    geom_density(aes(x = old_score, y = ..scaled..), data = df, fill = "black",
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
    xlab("Log Score Threshold") + ylab("Precision / Recall") +
    plot_theme

ggsave('../../manuscript/figures/ncsl_prec_rec_old.png', width = p_width, 
       height = 0.65 * p_width)


# F1 score
f1 <- prec_rec[, 1] * prec_rec[ , 2] / (prec_rec[, 1] + prec_rec[ ,2])
df1 <- data.frame("f1_score" = f1, "threshold" = thresholds)

ggplot(df1) + 
    geom_line(aes(x = thresholds, y = f1_score))

# Distributions of alignment scores in same table and not same table
score_st <- filter(df, same_table==1 & !is.na(score)) %>% select(score)
score_st <- score_st$score

score_nst <- filter(df, same_table==0 & !is.na(score)) %>% select(score)
score_nst <- score_nst$score

df2 <- data.frame(score = c(score_st, score_nst), 
                  group = c(rep("same_table", length(score_st)), 
                            rep("not_same_table", length(score_nst))))
ggplot(df2) + 
    geom_histogram(aes(x=score, y=..ncount../sum(..ncount..)), 
                   fill = cbPalette[1], color = "white", bins=30) +
    theme_bw() + facet_wrap(~group, ncol=1) + 
    ylab("Proportion") + xlab("Alignment Score")
ggsave('../../manuscript/figures/align_distri_ncsl_tables.png')