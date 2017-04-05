library(dplyr)
library(xtable)

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Function definitions
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fast_read <- function(filename) {
    samp <- read.table(filename, header = TRUE, nrows = 2, stringsAsFactors = FALSE,
                       sep = ',')
    classes <- sapply(samp, class)
    return(read.table(filename, header = TRUE, colClasses = classes,
                      stringsAsFactors = FALSE, sep = ',', comment.char = "",
                      fileEncoding = 'utf-8'))
}


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Main program
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Bill to bill alignment scores
alignments <- tbl_df(fast_read('../../data/aligner_output/alignments_notext.csv')) %>%
    filter(!is.na(score)) %>%
    mutate(relative_lucene_score = lucene_score / max_lucene_score)

cat("========================================================================\n")
cat("Descriptive statistics for alignments\n")
cat("========================================================================\n")

r <- range(alignments$score)

# Descriptive stats for alignment dataset
sink('../../manuscript/tables/alignments_descriptives.yml')
cat(paste0("n_bill_dyads: ", nrow(alignments), '\n'))
cat(paste0("mean_score: ", mean(alignments$score), '\n'))
cat(paste0("median_score: ", median(alignments$score), '\n'))
cat(paste("range:", r[1], r[2], '\n'))
cat(paste("n_alignments_gt_50:", sum(alignments$score > 50), '\n'))
cat(paste("n_alignments_gt_100:", sum(alignments$score > 100), '\n'))
cat(paste("n_alignments_gt_1000:", sum(alignments$score > 1000), '\n'))
sink()

## Distribution of alignment scores
thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))

hm <- function(threshold) sum(alignments$score < threshold) / nrow(alignments)
cumdist <- sapply(thresholds, hm)
pdat <- tbl_df(data.frame("Proportion" = cumdist, "Score" = thresholds))

# Load commont theme elements for plots
source('../plot_theme.R')

p <- ggplot(pdat) + 
    geom_line(aes(x = Score, y = Proportion), size = 1.2) + 
    scale_x_log10(breaks=c(1, 10, 100, 1000, 10000)) + 
    xlab("X") +
    ylab("P(Score < X)") +
    plot_theme
ggsave('../manuscript/figures/alignment_score_distribution.png', width = p_width, 
       height = 0.65 * p_width)

# Relationship of alignment and lucene score
p <- ggplot(alignments, aes(x = relative_lucene_score, y = score)) + 
    stat_binhex(bins = 150) +
    scale_y_log10() +
    xlab("Lucene Score") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = cbPalette[1], high = cbPalette[2], trans = "log",
                        labels = function (x) round(x, 0)) +
    guides(fill=guide_legend(title="Count")) +
    plot_theme
cat('Saving plot...\n')
ggsave(plot = p, '../manuscript/figures/alignment_lucene.png', 
       width = p_width, height = 0.65 * p_width)

## Bill metadata
#ret_last <- function(x) return(x[length(x)])
#ret_first <- function(x) return(x[1])
#meta <- tbl_df(read.csv('../../data/bill_metadata.csv', 
#                        stringsAsFactors = FALSE)) %>% 
#    mutate(state_id = sapply(strsplit(unique_id, '_'), ret_last),
#           year = as.integer(sapply(strsplit(date_introduced, '-'), ret_first)))
#
#filter(meta, (state == "nj" & state_id == "S2360"))
#
#filter(meta, (state == 'az' & state_id == "SB1070" & year == 2011)) %>%
#    select(unique_id, bill_title)
#
#
## Example Tables
#
#other_bill <- function(x, y, name) ifelse(x != name, x, y)
#
### Recycling act
#mo_2013_SB363 <- as.data.frame(filter(btb, (left_doc_id == "mo_2013_SB363" | 
#                                        right_doc_id == "mo_2013_SB363"))) %>% 
#    arrange(left_doc_id, sum_score) %>%
#    mutate(matched_bill = other_bill(left_doc_id, right_doc_id, "mo_2013_SB363")) %>%
#    dplyr::select(matched_bill, sum_score, ideology_dist, 
#                  left_length, right_length)
#
#
### Balanced Budget act
#nc_2015_HB366 <- as.data.frame(filter(btb, (left_doc_id == "nc_2015_HB366" | 
#                                        right_doc_id == "nc_2015_HB366"))) %>% 
#    arrange(left_doc_id, sum_score) %>%
#    mutate(matched_bill = other_bill(left_doc_id, right_doc_id, "nc_2015_HB366")) %>%
#    dplyr::select(matched_bill, sum_score, ideology_dist, 
#                  left_length, right_length)
#
#st <- sapply(strsplit(nc_2015_HB366$matched_bill, "_"), ret_first)
#sess <- sapply(strsplit(nc_2015_HB366$matched_bill, "_"), function(x) x[2])
#id_ <- sapply(strsplit(nc_2015_HB366$matched_bill, "_"), function(x) x[3])
#
#res_tab <- data.frame("ID" = id_, State = toupper(st), Session = sess, 
#                      score = nc_2015_HB366$sum_score)
#
#colnames(res_tab) <- c("Matched Bill", "Alignment Score")
#xtable(res_tab, caption = "Bills that align with NC HB366 (2015). The first three
#       columns identify the bill, the fourth column contains the alignment score
#       for the bill dyad. The score is the sum of the section alignments.")
#
#
## Get the actual alignments 
#alignments <- s]