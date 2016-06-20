library(ggplot2)
library(xtable)
library(quantreg)
library(dplyr)

#Plotting parameters
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
               "#D55E00", "#CC79A7")
p_width <- 11.5
# ==============================================================================
# Data preprocessing
# ==============================================================================

# # Metadata
# meta <- read.csv('../../data/lid/bill_metadata.csv', stringsAsFactors = FALSE,
#                  header = TRUE, quote = '"')
# 
# ## Clean it up
# meta$session <- NULL
# ### Make 'None' NA
# meta[meta == 'None'] <- NA
# ### Fix column classes
# for(i in grep("date_", names(meta))){
#     var <- sapply(as.character(meta[, i]), substr, 1, 10)
#     meta[, i] <- as.Date(x = var)
# }
# for(col in c("state", "chamber", "bill_type")){
#     meta[, col] <- as.factor(meta[, col])
# }
# meta$sponsor_idology <- as.numeric(meta$sponsor_idology)
# meta$num_sponsors <- as.integer(meta$num_sponsors)
# meta$bill_length <- as.integer(meta$bill_length)
# 
# ## Make dplyr object
# meta <- tbl_df(meta)
# 
# # Alignments
# # 1000
# alignments <- tbl_df(read.csv('../../data/lid/alignments_1000_b2b_ns.csv', 
#                               header = TRUE, stringsAsFactors = FALSE
# #                              , nrows = 1000
#                               )
#                      )
# 
# ## Match alignments with ideology scores and document length
# ### Join info on left bill
# temp <- mutate(meta, left_doc_id = unique_id, left_ideology = sponsor_idology,
#                left_length = bill_length) %>%
#     dplyr::select(left_doc_id, left_ideology, left_length)
# df <- left_join(alignments, temp, by = "left_doc_id")
# 
# ### Join info on right bill
# temp <- mutate(meta, right_doc_id = unique_id, right_ideology = sponsor_idology,
#                right_length = bill_length) %>%
#     dplyr::select(right_doc_id, right_ideology, right_length)
# df <- left_join(df, temp, by = "right_doc_id")
# 
# # Calculate ideological distance and combined doc length
# df <- mutate(df, ideology_dist = (left_ideology - right_ideology)^2)
# 
# aggr <- df
# 
# aggr$left_length <- NULL
# aggr$right_length <- NULL
# aggr$left_ideology <- NULL
# aggr$right_ideology <- NULL
# aggr$dyad_id <- NULL
# aggr$combined_length <- NULL
# rm(df, alignments, temp)
# gc()


# ==============================================================================
# Data Descriptives
# ==============================================================================

# Number of bills with ideology scores
length(which(!is.na(meta$sponsor_idology))) / nrow(meta)

# Number of dyads with ideology distance
length(which(!is.na(aggr$ideology_dist))) / nrow(aggr)

# Distribution of distance and log(score)
#ggplot(aggr) + geom_histogram(aes(ideology_dist), color = "white")


# ==============================================================================
# Ideology plot
# ==============================================================================

# # Write bill dyads to disk (that have ideological distance)
# aggr <- na.omit(aggr)
# write.csv(aggr, file = "../../data/lid/alignments_1000_b2b_ideology.csv", 
#            row.names = FALSE, fileEncoding = "utf-8")
# 
# aggr <- tbl_df(read.csv("../../data/lid/alignments_1000_b2b_ideology.csv",
#                  stringsAsFactors = FALSE))
# 
# #aggr <- aggr[sample(c(1:nrow(aggr)), 100000, replace=FALSE), ]
#                 
# # Conditional boxplots
# 
# # Get cumulative frequency for ideology_dist
# freq_tab <- group_by(aggr, ideology_dist) %>% 
#     summarize(freq = n()) %>%
#     arrange(ideology_dist) %>%
#     mutate(cumu = cumsum(freq))
# 
# # Get the binsize
# n <- nrow(aggr)
# nbin <- 30
# s <- n / nbin
# 
# # Assign distance values to bins
# freq_tab <- freq_tab %>% mutate(bin = round(cumu / s, 0) + 1) 
# 
# # Get and inspect the cutpoints
# cutpoints <- group_by(freq_tab, bin) %>% summarize(cutpoint = max(ideology_dist))
# ggplot(cutpoints) + geom_point(aes(x = bin, y = cutpoint))
# 
# # Prepare aggr for plotting the boxplots
# freq_tab <- dplyr::select(freq_tab, ideology_dist, bin)
# aggr <- left_join(aggr, freq_tab, by = "ideology_dist")
# 
# # Make bins a factor
# aggr <- mutate(aggr, bin = as.factor(bin))
# 
# # Calc 95th percentile in each bin
# #q90 <- group_by(aggr, bin) %>% summarize(q95 = quantile(alignment_score, 0.95)) 
# #q95 <- group_by(aggr, bin) %>% summarize(q95 = quantile(alignment_score, 0.95)) 
# #q97 <- group_by(aggr, bin) %>% summarize(q95 = quantile(alignment_score, 0.95)) 
# #q99 <- group_by(aggr, bin) %>% summarize(q95 = quantile(alignment_score, 0.95)) 
# q999 <- group_by(aggr, bin) %>% summarize(q95 = quantile(alignment_score, 0.95)) 
# 
# aggr <- left_join(aggr, q95, by = "bin")
# 
# # Plot it
# #ylim1 <- boxplot.stats(aggr$alignment_score)$stats[c(1,5)]
# ylim1 <- c(0, 60)
# 
# p <- ggplot(aggr) + 
#     geom_boxplot(aes(x = bin, y = alignment_score), outlier.size = 0.1,
#                  outlier.colour = "grey") + 
#     geom_point(aes(x = bin, y = q95), col = cbPalette[2]) + 
#     theme_bw() + coord_cartesian(ylim = ylim1) + 
#     scale_x_discrete(labels = round(cutpoints$cutpoint, 3)) + 
#     theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
#     theme(axis.text=element_text(size=12),
#           axis.title=element_text(size=14),
#           legend.text=element_text(size=12))
# ggsave(plot = p,
#        filename = '../../4344753rddtnd/figures/ideology_alignment_1000_boxplot.png',
#        width = p_width, height = 0.65 * p_width)
#save(aggr, file = "ideology_analysis.RData")

load("ideology_analysis.RData")
## Descriptive scatterplot on sample of points
n <- 20
qs <- seq(0.95,0.999, length.out = n)
qs <- c(qs, seq(qs[n-1], qs[n], length.out = 4)[-c(1,4)])
set.seed(08361233431)
paggr <- aggr[sample(c(1:nrow(aggr)), 100000, replace = FALSE), ]
p <- ggplot(paggr) + 
    geom_point(aes(x = ideology_dist, y = alignment_score), alpha = 0.2, size = 0.5) + 
    stat_quantile(aes(y = alignment_score, x = ideology_dist), quantiles = qs) +
    theme(axis.text=element_text(size=12),
          axis.title=element_text(size=14),
          legend.text=element_text(size=12)) +
    theme_bw() +
    xlab("Ideological Distance") + 
    ylab("Alignment Score")
ggsave(plot = p, '../../4344753rddtnd/figures/ideology_alignment_1000.png', 
       width = p_width, height = 0.65 * p_width)

quant_reg <- function(q) {
    mod <- rq(alignment_score ~ ideology_dist, data = paggr, tau = q) 
    cat("done\n")
    return(mod) 
}
mods <- lapply(qs, quant_reg)
coefs <- sapply(mods, function(x) return(coef(x)[2]))
df <- data.frame(quantile = qs, coefficient = coefs)
df <- df[order(df$quantile, decreasing = FALSE), ]
xtable(df, digits = 3)

