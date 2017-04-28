library(dplyr)
library(ggplot2)
library(xtable)
library(ROCR)
library(pROC)
library(doParallel)
library(pracma)

#_ Load the ncsl alignment raw data
retx <- function(x, i) x[i] 
indat <- '../../data/aligner_output/ncsl_alignments_notext.csv'
ncsl_alignments <- tbl_df(read.csv(indat, stringsAsFactors = FALSE)) %>%
    mutate(score = adjusted_alignment_score, adjusted_alignment_score = NULL) %>%
    group_by(left_id, right_id) %>%
    summarize(score = sum(score), count = n()) %>%
    mutate(left_state = sapply(strsplit(left_id, "_"), retx, 1),
           right_state = sapply(strsplit(right_id, "_"), retx, 1)) %>%
    filter(left_state != right_state) %>%
    select(-left_state, -right_state)

# Load the ncsl table dataset
ncsl_bills <- tbl_df(read.csv('../../data/ncsl/ncsl_data_from_sample_matched.csv',
                              stringsAsFactors = FALSE, header = TRUE)) %>%
    filter(!is.na(matched_from_db))

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
                        by = c("left_doc_id" = "left_id", 
                               "right_doc_id" = "right_id"))
# Sanity check: match with alignmetns from general alignment algo
#bill_pairs <- left_join(df, alignments, 
#                        by = c("left_doc_id", "right_doc_id"))

df <- filter(bill_pairs, !is.na(score)) %>%
    select(-left_table, -right_table)

## Join with the cosine similarity scores
ncsl_cosine <- tbl_df(read.csv('../../data/ncsl/cosine_similarities.csv', 
                               stringsAsFactors = FALSE, header = TRUE))
df <- left_join(df, ncsl_cosine, by = c("left_doc_id", "right_doc_id"))
rm(bill_pairs)

source('../plot_theme.R')

p <- ggplot(df, aes(x = cosine_similarity, y = score)) + 
    stat_binhex(bins = 30) +
    scale_y_log10() +
    xlab("Cosine Similarity") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = cbPalette[1], high = cbPalette[2],
                        labels = function (x) round(x, 0)) +
    guides(fill=guide_legend(title="Count")) +
    plot_theme
ggsave(plot = p, '../../paper//figures/ncsl_alignment_cosine.png', 
       width = p_width, height = 0.65 * p_width)

# Write out the list of ncsl bill ids (lid format)
#out_ids <- unique(df$left_doc_id)
#writeLines(out_ids, con = '../data/ncsl_analysis/ncsl_analysis.')

# Remove 0 scores
df <- filter(df, score != 0)

df_nosplit <- df
df_cosim <- select(df, -count, -score) %>%
    mutate(score = cosine_similarity, cosine_similarity = NULL)

# Descriptives
# ==============================================================================

# Alignment examples
# TODO: regenerate for new alignments
#align_text <- tbl_df(read.table('../../data/ncsl/ncsl_unique_align.csv',
#                                sep = ',', stringsAsFactors = FALSE,
#                                header = TRUE)) %>%
#    arrange(desc(count))
## 4 most commont
#fmc <- head(align_text, 5)
#
## Make table:
#sink('../../manuscript/tables/align_exmpls.tex')
#xtable(fmc)
#sink()

# Precision recall plots and area under the curve
# ==============================================================================

# Precision / recall function
pr <- function(threshold, score, true) {
    predicted <- ifelse(score >= threshold, 1, 0)
    p <- length(which(predicted == 1))
    tp <- length(which(predicted == 1 & true == 1))
    precision <- tp / p 
    fn <- length(which(predicted == 0 & true == 1))  
    recall <- tp / (tp + fn) 
    return(c(precision, recall))
}

# Area under precision recall curve
auprc <- function(score, true) {
    p <- prediction(score, true)
    prec_rec <- performance(p, measure = 'rec', x.measure = 'prec')
    precision <- prec_rec@x.values[[1]][-1]
    recall <- prec_rec@y.values[[1]][-1]
    area <-  trapz(recall, precision)
    return(area)
}

# Precision recall curve and AUC function
prc_auc <- function(dat, cosim=FALSE) {
    
    # Get precision and recall for all thresholds
    score <- dat$score
    true <- dat$same_table
    r <- range(score, na.rm = TRUE)
    if(cosim) thresholds <- seq(r[1], r[2], length.out = 100)
    else thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))
    prec_rec <- t(sapply(thresholds, pr, score = score, true = true))
    df_1 <- data.frame(value = c(prec_rec[, 1], prec_rec[, 2]),
                 threshold = rep(c(thresholds), 2),
                 type = rep(c("precision", "recall"), each = nrow(prec_rec)))
    
    # Make the plot
    if(cosim){
    plt <- ggplot(df_1) + 
        geom_density(aes(x = score, y = ..scaled..), data = dat, fill = "black",
                     alpha = 0.05, color = "white", adjust = 4) +
        geom_line(aes(y = value, x = threshold, color = type, linetype = type),
                  size = 2) + 
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
    } else {
     plt <- ggplot(df_1) + 
        geom_density(aes(x = score, y = ..scaled..), data = dat, fill = "black",
                     alpha = 0.05, color = "white", adjust = 4) +
        geom_line(aes(y = value, x = threshold, color = type, linetype = type),
                  size = 2) + 
        scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1, 1.25)) +
        scale_x_log10(breaks = c(1, 10, 100, 1000, 10000)) +
        geom_hline(aes(yintercept = 1), linetype = 2, alpha = 0.2) +
        scale_color_manual(values = cbPalette, 
                           labels = c("Precision", "Recall"),
                           name = "") +
        scale_linetype_manual(values = c(1, 3), 
                           labels = c("Precision", "Recall"),
                           name = "") +
        xlab("Score Threshold") + ylab("Precision / Recall") +
        plot_theme       
    }
       
    # Area under the curve 
    auc <- auprc(dat$score, dat$same_table)
    
    return(list("prp" = plt, "auc" = auc))
}


# Make plots and get measures for all three scores
auc_tab <- as.data.frame(matrix(NA, nc = 1, nr = 3))
rownames(auc_tab) <- c("Random", "Cosine", "Alignment")
auc_tab[, 2] <- NA
auc_tab[, 3] <- NA
colnames(auc_tab) <- c("AUC", "P(X<Random)", "P(X<Cosine)")

## Random classifier
score <- runif(nrow(df_nosplit))
true <- df_nosplit$same_table
auc_tab[1, 1] <- auprc(score, true)

## Cosine similarity
out_cosim <- prc_auc(df_cosim, cosim=TRUE)
auc_tab[2, 1] <- out_cosim$auc
ggsave(filename = '../../paper/figures/ncsl_pr_cosm.png', 
       plot = out_cosim$prp, width = p_width, height = 0.65 * p_width)

## Alignment Score
out_nosplit <- prc_auc(df_nosplit)
auc_tab[3, 1] <- out_nosplit$auc
ggsave(filename = '../../paper/figures/ncsl_pr_nosplit.png', 
       plot = out_nosplit$prp, width = p_width, height = 0.65 * p_width)

## Bootstrap AUC differences

### Prep data
df <- select(df_nosplit, -cosine_similarity, -count)
df_random <- df %>% mutate(score = runif(nrow(df)))

### Function for each bootstrap iteration
roc_bs <- function(){
    # Draw bs sample
    dr <- df_random[sample(c(1:nrow(df_random)), nrow(df_random), replace = TRUE), ]
    dc <- df_cosim[sample(c(1:nrow(df_cosim)), nrow(df_cosim), replace = TRUE), ]
    da <- df[sample(c(1:nrow(df)), nrow(df), replace = TRUE), ]
    
    # Area under the curve for each measure
    ra <- auprc(dr$score, dr$same_table) 
    al <- auprc(da$score, da$same_table) 
    co <- auprc(dc$score, dc$same_table) 
    
    return(list(al, co, ra))  
}

### Run in parallel
cl <- makeCluster(12)
registerDoParallel(cl)
B <- 2000
roc_res <- foreach(i=1:B, .packages = c("ROCR", "pracma")) %dopar% roc_bs() 

## Process parallel output
b <- roc_res
roc_res <- tbl_df(as.data.frame(t(sapply(roc_res, function(x) unlist(x)))))
colnames(roc_res) <- c("Alignment", "Cosine", "Random")

## Get P-values
auc_tab[2, 2] <- sum(roc_res$Random > roc_res$Cosine) / B
auc_tab[3, 2] <- sum(roc_res$Random > roc_res$Alignment) / B
auc_tab[3, 3] <- sum(roc_res$Cosine > roc_res$Alignment) / B

# Make the results table
sink('../../paper/tables/ncsl_auc.tex')
xtable(auc_tab, digits = 2, caption = paste("Area under the precision-recall curve for classifier based
       on thresholding alignment scores (Alignment), classifier based on 
       thresholding cosine similarity score (Cosine) and random 
       classifier (Random). The last three columns report one-tailed p-values for 
       comparison between the AUCs. p-values are derived from", B, "non-parametric
       bootstrap iterations."), label = "tab:ncsl_auc")
sink()

# Distribution stats

# Frequency of scores higher 50 / 100
sink('../../paper/tables/prec_rec_distri.txt')
cat(paste0('Frequency of scores higher than 5: '), 
    sum(df_nosplit$score > 50) / nrow(df_nosplit),
    '\n')
cat(paste0('Frequency of scores higher than 7: '), 
    sum(df_nosplit$score > 100) / nrow(df_nosplit),
    '\n')
cat(paste0('Proportion in same table: '), 
    sum(df_nosplit$same_table) / nrow(df_nosplit),
    '\n')
sink()

# Clustered bootstrap regression model

## Model
mod <- lm(log(score) ~ same_table, data = df_nosplit)

## Uncertainty using the bootstrap
B <- 1000

clusters <- unique(df$left_doc_id)
nc <- length(clusters)
out <- matrix(rep(NA, B * 2), nc = 2, nr = B)
out_cs <- matrix(rep(NA, B * 2), nc = 2, nr = B)

for(i in 1:B) {
    
    # Sample clusters and build iteration-dataset
    sc <- sample(clusters, nc, replace = TRUE)
    dat <- filter(df_nosplit, is.element(left_doc_id, sc))
    
    # fit models 
    bs_mod <- lm(log(score) ~ same_table, data = dat)
    coefs <- coef(bs_mod)
    out[i, ] <- coefs
        
    if(i %% 10 == 0){
        print(i)
    }
}

## Make the table
ci <- quantile(out[, 2], c(0.025, 0.975))
b <- coef(mod)[2]

reg_tab <- as.data.frame(matrix(NA, nc = 3, nr = 1))
colnames(reg_tab) <- c("Coefficient", "Std. Error", "95\\% CI")
rownames(reg_tab) <- c("Same Table")
reg_tab[1, ] <- c(round(b, 3), round(sd(out[, 2]), 3), paste(round(ci[1], 3), round(ci[2], 3)))

sink('../../paper/tables/ncsl_bs_reg.tex')
xtable(reg_tab, digits = 3)
sink()
