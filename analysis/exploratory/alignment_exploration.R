library(dplyr)
library(xtable)
library(ggplot2)
library(data.table)
library(dtplyr)

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Main program
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Bill to bill alignment scores
alignments <- fread('../../data/aligner_output/alignments_notext.csv', 
                    verbose = TRUE) %>%
    filter(!is.na(score)) %>%
    filter(score > 0)
    #mutate(relative_lucene_score = lucene_score / max_lucene_score)

cat("========================================================================\n")
cat("Descriptive statistics for alignments\n")
cat("========================================================================\n")

r <- range(alignments$score)

# Descriptive stats for alignment dataset
print('Stats...')
sink('../../paper/tables/alignments_descriptives.yml')
cat(paste0("n_bill_dyads: ", nrow(alignments), '\n'))
cat(paste0("mean_score: ", mean(alignments$score), '\n'))
cat(paste0("median_score: ", median(alignments$score), '\n'))
cat(paste("range:", r[1], r[2], '\n'))
cat(paste("n_alignments_gt_50:", sum(alignments$score > 50), '\n'))
cat(paste("n_alignments_gt_100:", sum(alignments$score > 100), '\n'))
cat(paste("n_alignments_gt_1000:", sum(alignments$score > 1000), '\n'))
sink()

## Distribution of alignment scores
print('Distribution plot...')
thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))

hm <- function(threshold) {
    freq <- sum(alignments$score > threshold) 
    prop <- sum(alignments$score < threshold) / nrow(alignments)
    return(c(freq, prop))
}
cumdist <- do.call(rbind, lapply(thresholds, hm))

pdat <- tbl_df(data.frame("proportion_lt" = cumdist[, 2], "score" = thresholds,
                          "frequency_gt" = cumdist[, 1]))

# Load commont theme elements for plots
source('../plot_theme.R')
d0_100 <- filter(pdat, score <= score[40])
d100_1000 <- filter(pdat, score >= score[40] & score <= score[66])
d1000 <- filter(pdat, score >= score[66])
n <- nrow(alignments)
n0_100 <- n * pdat$proportion_lt[40]
n100_1000 <- n * pdat$proportion_lt[66] - n0_100
n1000 <- n - n0_100 - n100_1000
p <- ggplot(pdat, aes(x = score, y = proportion_lt)) + 
    scale_x_log10(breaks=c(1, 10, 100, 1000, 10000)) + 
    geom_area(data = d0_100, 
              aes(x = score, y = proportion_lt),
              fill = cbPalette[1], alpha = 0.5) +
    geom_area(data = d100_1000, 
              aes(x = score, y = proportion_lt),
              fill = cbPalette[2], alpha = 0.5) +   
    geom_area(data = d1000, 
              aes(x = score, y = proportion_lt),
              fill = cbPalette[3], alpha = 0.5) +
    geom_label(aes(x = score[30], y = 0.5), label = "224m", 
               color = cbPalette[1], size = 10) +
    geom_label(aes(x = score[52], y = 0.5), label = "1.3m", 
               color = cbPalette[2], size = 10) +
    geom_label(aes(x = score[83], y = 0.5), label = "43,000", 
               color = cbPalette[3], size = 10) +
    geom_line(size = 1.2) + 
    xlab("Alignment Score") +
    ylab("Proportion < Score") +
    plot_theme
ggsave(plot = p, '../../paper/figures/alignment_score_distribution.png', width = p_width, 
       height = 0.65 * p_width)

# Relationship of alignment and lucene score
#p <- ggplot(alignments, aes(x = relative_lucene_score, y = score)) + 
#    stat_binhex(bins = 150) +
#    scale_y_log10() +
#    xlab("Lucene Score") + 
#    ylab("Alignment Score") + 
#    scale_fill_gradient(low = cbPalette[1], high = cbPalette[2], trans = "log",
#                        labels = function (x) round(x, 0)) +
#    guides(fill=guide_legend(title="Count")) +
#    plot_theme
#cat('Saving plot...\n')
#ggsave(plot = p, '../../paper/figures/alignment_lucene.png', 
#       width = p_width, height = 0.65 * p_width)

# Plot the scores by bill
p <- ggplot(arrange(alignments, desc(adjusted_alignment_score))) + 
    geom_point(aes(x=factor(left_id, levels = unique(left_id)), 
                            y = adjusted_alignment_score), alpha = 0.005, 
               size = 0.001) +
    scale_y_log10(breaks = c(3, 10, 100, 1000, 10000)) + 
    theme_bw() +
    theme(axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title=element_text(size=22),
          axis.text.y=element_text(size=16),
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank()) +
    ylab("Alignment Score") + xlab("Bill")
ggsave(plot = p, '../../paper/figures/scores_by_bill.png', width = p_width, 
       height = 0.65 * p_width)
  
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
stop()
count_words <- function(x) as.numeric(length(unlist(strsplit(x, ' '))))
db_connection = src_postgres('text_reuse')
alignments = tbl(db_connection, "alignments") %>%
    filter(!is.na(adjusted_alignment_score)) %>%
    head(5e6) %>%
    left_join(tbl(db_connection, "bill_metadata"), 
              by = c("left_id" = "unique_id")) %>%
    left_join(tbl(db_connection, "bill_metadata"), 
              by = c("right_id" = "unique_id"), suffix = c(".left", ".right")) %>%
    filter(!is.na(sponsor_ideology.right), !is.na(sponsor_ideology.left)) %>%
    tbl_df()

alignments <- mutate(alignments, 
                     left_aligned = sapply(left_alignment_text, count_words) /
                         bill_length.left,
                     right_aligned = sapply(left_alignment_text, count_words) /
                         bill_length.right) %>%
    select(right_aligned, left_aligned, sponsor_ideology.right, 
           sponsor_ideology.left, left_id, right_id)

df = data_frame(prop_aligned = c(alignments$right_aligned, 
                                 alignments$left_aligned),
                ideology = c(alignments$sponsor_ideology.right,
                             alignments$sponsor_ideology.left),
                bill_id = c(alignments$right_id, alignments$left_id)) %>%
    group_by(bill_id) %>%
    summarize(prop_aligned = max(prop_aligned), 
              ideology = ideology[1])

# Proportion aligned by ideology
source('../plot_theme.R')
ggplot(df, aes(x = ideology, y = prop_aligned)) +
    stat_binhex(bins = 50) +
    scale_y_log10() + 
    plot_theme

ggplot(df, aes(x = ideology, y = prop_aligned)) +
    geom_point(alpha = 0.1, size = 0.5) +
    scale_y_log10() + 
    plot_theme
   

states = group_by(largest_alignments, state.left, state.right) %>%
    summarize(count = n(), mean = mean(adjusted_alignment_score), 
              sum = sum(adjusted_alignment_score)) %>%
    arrange(desc(count), desc(mean), desc(sum))

# Adjusted vs unweighted score distribution
scores = tbl(db_connection, "alignments") %>%
    select(score, adjusted_alignment_score) %>%
    filter(score != 0, !is.na(adjusted_alignment_score)) %>%
    mutate(difference_absolute = score - adjusted_alignment_score,
           perc_difference = ((score - adjusted_alignment_score) / score) * 100) %>%
    tbl_df()


## Distribution of alignment scores
r <- range(scores$score)
thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))

hm <- function(threshold) c(sum(scores$score < threshold) / nrow(scores),
                            sum(scores$adjusted_alignment_score < threshold) / nrow(scores))
cumdist <- do.call(rbind, lapply(thresholds, hm))

pdat <- tbl_df(data.frame("proportion_score" = cumdist[, 1], 
                          "proportion_adjusted_score" = cumdist[, 2],
                          "score" = thresholds))

p <- ggplot(pdat) + 
    geom_line(aes(x = score, y = proportion_score), size = 1.2) + 
    geom_line(aes(x = score, y = proportion_adjusted_score), size = 1.2) + 
    scale_x_log10(breaks=c(1, 10, 100, 1000, 10000)) + 
    xlab("X") +
    ylab("P(Score < X)") +
    plot_theme

## distribution of differnces
ggplot(scores) +
    geom_density(aes(x = perc_difference))

## Relationship of 
scores$sample = sample(1:nrow(scores), nrow(scores), replace = FALSE)
scores_sample = filter(scores, sample < 100000) %>%
    select(-sample)

ggplot(scores_sample, aes(x = perc_difference, y = score)) +
    geom_point(alpha = 0.3, size = 0.5) +
    geom_smooth() +
    scale_y_log10() +
    plot_theme

## distribution of proportions aligned
r <- range(df$prop_aligned)
thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))

hm <- function(threshold) sum(df$prop_aligned < threshold) / nrow(df)
cumdist <- sapply(thresholds, hm)

pdat <- tbl_df(data.frame("proportion" = cumdist, 
                          "score" = thresholds))

p <- ggplot(pdat) + 
    geom_line(aes(x = score, y = proportion), size = 1.2) + 
    scale_x_log10(breaks = c(0, 0.001, 0.01, 0.1, 1)) + 
    xlab("X") +
    ylab("P(Ratio < X)") +
    plot_theme
ggsave(p, filename = '../../conference_materials/presentation/5994341jpqjcz/images/prop_aligned_distri.png',
       width = p_width, height = 0.7*p_width)

ggplot(df) + 
    geom_density(aes(x = prop_aligned)) +
    scale_x_log10()
