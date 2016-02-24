library(dplyr)
library(ggplot2)
library(xtable)
library(MCMCpack)

source("qap.R")

#Plotting colors
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
               "#D55E00", "#CC79A7")
# ==============================================================================
# Data preprocessing
# ==============================================================================


# This loads the preprocessed data:
load("qap_data.RData")
# If not available uncommet code below


# # Metadata
# meta <- read.csv('../../data/bill_metadata.csv', stringsAsFactors = FALSE,
#                  header = TRUE, quote = '"')
# 
# ## Clean it up
# meta$session <- NULL
# ### Make 'None' NA
# meta[meta == 'None'] <- NA
# ### Fix column classes
# for(i in grep("date_", names(meta))){
#     var <- sapply(as.character(meta[, i]), substr, 1, 10)
#     var
#     meta[, i] <- as.Date(x = var)
# }
# for(col in c("state", "chamber", "bill_type")){
#     meta[, col] <- as.factor(meta[, col])
# }
# meta$sponsor_idology <- as.numeric(meta$sponsor_idology)
# meta$num_sponsors <- as.integer(meta$num_sponsors)
# 
# ## Make dplyr object
# meta <- tbl_df(meta)
# 
# # Alignments
# alignments <- tbl_df(read.csv('../../data/lid/bill_to_bill_scores_only.csv', 
#                               header = TRUE, stringsAsFactors = FALSE))
# 
# ## Match alignments with ideology scores
# temp <- mutate(meta, left_doc_id = unique_id, left_ideology = sponsor_idology) %>%
#     dplyr::select(left_doc_id, left_ideology)
# df <- left_join(alignments, temp, by = "left_doc_id")
# temp <- mutate(meta, right_doc_id = unique_id, right_ideology = sponsor_idology) %>%
#     dplyr::select(right_doc_id, right_ideology)
# df <- left_join(df, temp, by = "right_doc_id")
# df <- mutate(df, ideology_dist = (left_ideology - right_ideology)^2,
#              dyad_id = as.factor(paste0(left_doc_id, right_doc_id)))
# 
# # Aggregate to bill level
# aggr <- group_by(df, left_doc_id, right_doc_id) %>%
#     summarize(sum_score = sum(alignment_score), 
#               ideology_dist = ideology_dist[1],
#               left_ideology = left_ideology[1],
#               right_ideology = right_ideology[1]) %>% 
#     filter(!is.na(ideology_dist))
# 
# rm(df, alignments, temp)
# gc()
# 
# # ==============================================================================
# # Descriptives
# # ==============================================================================
# 
# # Number of bills with ideology scores
# length(which(!is.na(meta$sponsor_idology))) / nrow(meta)
# 
# # Number of dyads with ideology distance
# length(which(!is.na(aggr$ideology_dist))) / nrow(aggr)
# 
# # Distribution of distance and log(score)
# ggplot(aggr) + geom_histogram(aes(ideology_dist), color = "white")
# 

# Ideological distance vs sum_score
samp <- tbl_df(aggr[sample(c(1:nrow(aggr)), 1000), ])
ggplot(aggr, aes(x = ideology_dist, y = sum_score)) + 
    geom_point(alpha = 0.3, size = 1) + 
    #geom_smooth(method = "loess", size = 1.5) +
    scale_y_log10() + 
    xlab("Ideological Distance") +
    ylab("log Alignment Score (Sum)") + 
    theme_bw() 
ggsave('../../4344753rddtnd/figures/ideology_alignment.png')

#    Distribution of number of sponsors
nsp <- table(meta$num_sponsors)
pdat <- data.frame(cumu <- cumsum(as.integer(nsp)), 
                   nsp <- as.integer(names(nsp)))

ggplot(pdat) +
    geom_point(aes(x = nsp, y = cumu)) + theme_bw() + ylim(0, 7e5) +
    xlab("Number of Sponsors") + ylab("Cumulative Number of Bills")


many_sponsors <- filter(meta, num_sponsors > 50) %>% 
    arrange(-num_sponsors)
table(many_sponsors$state)

# # # ==============================================================================
# # # Analyses
# # # ==============================================================================
# 
# 
# # Prepare objects for the qap procedure
# aggr <- as.data.frame(aggr)
# 
# ## Get ideology scores
# ideology <- dplyr::select(meta, unique_id, sponsor_idology)
# ideology <- as.data.frame(ideology)
# 
# ## Generate fast lookup objects
# 
# ### Generate a mappin: bill_id -> integer_id
# n_dyads <- nrow(aggr)
# unique_bills <- unique(c(aggr$left_doc_id, 
#                          aggr$right_doc_id)) 
# n_bills <- length(unique_bills)
# ids <- as.list(c(1:n_bills))
# names(ids) <- unique_bills
# id_map <- list2env(ids, hash = TRUE, size = n_bills)
# 
# ### store ideology values in same order as integer ids
# ### for lookup by position 
# temp <- as.list(ideology[, 2])
# names(temp) <- ideology[, 1]
# ideo_map <- list2env(x = temp, hash = TRUE, size = nrow(ideology))
# rm(temp)
# ideo_lookup <- function(bill) get(x = bill, envir = ideo_map)
# ideologies <- sapply(unique_bills, ideo_lookup) 
# 
# ### Generate edgelist with integer ids for alignment network
# edges <- matrix(rep(NA, 3 * n_dyads), ncol = 3, nrow = n_dyads)
# get_from_envir <- function(i, col, df) {
#     get(x = df[i, col], envir = id_map)
# }
# edges[, 1] <- sapply(c(1:n_dyads), get_from_envir, col = 1, df = aggr)
# edges[, 2] <- sapply(c(1:n_dyads), get_from_envir, col = 2, df = aggr)
# 
# save.image("qap_data.RData")


# Run the models for different aggregation methods

# This loads the results:
load('qap_results.RData')
# If not available uncomment code below

# ## Number of qap permutations
# n_qap_perm <- 1000
# ## Number of cores for permutations
# n_cores <- 40
# 
# ## Linear model for sum aggregation (with qap standard errors)
# sum_score <- lm(log(sum_score) ~ ideology_dist, data = aggr)
# edges[, 3] <- aggr$sum_score
# perm_dist_sum <- qap(edges, ideologies, nperm = n_qap_perm, cores = n_cores)
# 
# # ==============================================================================
# # Output results
# # ==============================================================================
# 
# # Table for regression results
# res <- data.frame(Intercept = sum_score$coef[1],
#                   Estimate = sum_score$coef[2],
#                   Std.Dev = sqrt(var(perm_dist_sum)))
# rownames(res) <- NULL
# 
# # # Store results to disk
# save(list = c("sum_score", "perm_dist_sum"), file = "qap_results.RData")

res$p <- length(which(abs(perm_dist_sum) > abs(res[1, 2]))) / length(perm_dist_sum)

# Make latex results table
sink(file = '../../4344753rddtnd/tables/ideology_regs.tex')
xtable(res, digits = 3, caption = "Log-Linear model for alignment and euclidian 
       distance in ideology. Two tailed p-values are generated from quadratic 
       assignment procedure with 1000 iterations. Std.Dev is the standard 
       deviation of the null distribution.",
       label = "tab:ideology_regs")
sink()

# PLot distributions
n_qap_perm <- length(perm_dist_sum)
pdat <- data.frame(permutations = perm_dist_sum)

ests <- data.frame(aggregation = c("Sum", "Mean", "Max", "# Alignments"), 
                   beta = res$Estimate)

ggplot(pdat) + 
    geom_histogram(aes(permutations), color = "white", binwidth = 0.0005,
                 fill = "grey16") + 
    geom_vline(aes(xintercept = res$Estimate), color = cbPalette[2]) +
    geom_text(data = ests, aes(x = (beta - 0.001), y = 200, angle = 90, 
                               label = "Estimate", color = cbPalette[2]
                               ), show_guide = FALSE) +
    xlab("Coefficient") + ylab("Count") + 
    theme_bw()
ggsave('../../4344753rddtnd/figures/qap_dist.png')


# Substantive interpretation of effectsize

## Load Malp data to get median legislators of D and R
malp <- tbl_df(read.table('../../data/malp/malp_individual.tab', header = TRUE,
                          stringsAsFactors = FALSE, sep = "\t"))
median_legs <- group_by(malp, party) %>% 
    summarize(median_ideology = median(np_score),
              mean_ideology = mean(np_score),
              max_ideology = max(np_score),
              min_ideology = min(np_score),
              first_quart = quantile(np_score, 0.05),
              third_quart = quantile(np_score, 0.95))

# Histogram of ideologies
ggplot(malp) + 
    geom_density(aes(np_score, fill = party, color = party), alpha = 0.5) +
    scale_color_manual(values = cbPalette, 
                      labels = c("Democrat", "Independent", "Republican")) +
    scale_fill_manual(values = cbPalette, 
                      labels = c("Democrat", "Independent", "Republican")) +
    geom_segment(data = median_legs, aes(x = median_ideology, xend = median_ideology,
                                         y = 1.25, yend = 0, color = party)) +
    xlab("Ideology") + ylab("Density") +
    theme_bw()
ggsave('../../4344753rddtnd/figures/ideo_distri.png')

med_to_med <- (median_legs$median_ideology[median_legs$party == "R"] - 
                   median_legs$median_ideology[median_legs$party == "D"])^2
ext_to_ext <- (median_legs$min_ideology[median_legs$party == "D"] - 
                   median_legs$max_ideology[median_legs$party == "R"])^2
q_to_q <- (median_legs$first_quart[median_legs$party == "D"] - 
                   median_legs$third_quart[median_legs$party == "R"])^2
delta_y <- function(dist) {
    exp(res$Intercept + res$Estimate * dist) - exp(res$Intercept)    
}

line_df <- data.frame(x = c(med_to_med, q_to_q, ext_to_ext),
                      val = c(delta_y(med_to_med), delta_y(q_to_q), 
                              delta_y(ext_to_ext)),
                      label = c("Median Dem to Median Rep", "0.05 to 0.95 Quantile",
                                "Min Dem to Max Rep"))

dists <- seq(0, 100, length.out = 200)
effects <- data.frame(distance = dists, delta_y = sapply(dists, delta_y))

ggplot(effects) + 
    geom_line(aes(x = distance, y = delta_y)) +
    xlab("Increase in squared distance from 0") + ylab(expression(Delta[mean_score])) + 
    geom_segment(data = line_df, 
                 aes(x = x, y = 0, yend = val, xend = x, color = label)) +
    scale_color_manual(values = cbPalette) +
    theme_bw()
ggsave('../../4344753rddtnd/figures/log_lin_effects.png')

## Effects plot with uncertainty
# 
# Doesn't work because we don't have a good estimate of the variance covariance
# matrix(?)
# 
# ## Draw betas
# beta <- mvrnorm(n = 1000, mu = coef(mean_score), Sigma = vcov(mean_score))
# 
# ## Make design matrix
# X <- cbind(rep(1, 200), seq(min(malp$np_score), max(malp$np_score), 
#                             length.out = 200))
# y_hat <- X %*% t(beta)
# 
# pdat <- data.frame(mean = apply(y_hat, 1, mean), 
#                    lo = apply(y_hat, 1, quantile, 0.025),
#                    hi = apply(y_hat, 1, quantile, 0.975))
# 
# ## Plot it
# ggplot(pdat) +
#     geom_segment(aes(x = X[, 2], xend = X[, 2], y = lo, yend = hi)) + 
#     geom_point(aes(x = X[, 2], y = mean))
#     



