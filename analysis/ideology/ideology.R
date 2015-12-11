library(dplyr)
library(ggplot2)
library(xtable)

source("qap.R")

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
#                               colClasses = c("factor", "factor", "numeric"),
#                               skip = 1, 
#                               #nrows = 1000
#                               ) )
# 
# ## Match alignments with ideology scores
# temp <- mutate(meta, left_doc_id = unique_id, left_ideology = sponsor_idology) %>%
#     select(left_doc_id, left_ideology)
# df <- left_join(alignments, temp, by = "left_doc_id")
# temp <- mutate(meta, right_doc_id = unique_id, right_ideology = sponsor_idology) %>%
#     select(right_doc_id, right_ideology)
# df <- left_join(df, temp, by = "right_doc_id")
# df <- mutate(df, ideology_dist = (left_ideology - right_ideology)^2,
#              dyad_id = as.factor(paste0(left_doc_id, right_doc_id)))
# 
# ## Aggregate to bill level
# aggr <- group_by(df, left_doc_id, right_doc_id) %>%
#     summarize(sum_score = sum(alignment_score), n_align = n(),
#               mean_score = mean(alignment_score), 
#               max_score = max(alignment_score),
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
# # ==============================================================================
# # Analyses
# # ==============================================================================
# 
# 
# # Prepare objects for the qap procedure
# aggr <- as.data.frame(aggr)
# 
# ## Get ideology scores
# ideology <- select(meta, unique_id, sponsor_idology)
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
# n_cores <- 36
# 
# ## Linear model for sum aggregation (with qap standard errors)
# sum_score <- lm(log(sum_score) ~ ideology_dist, data = aggr)
# edges[, 3] <- aggr$sum_score
# perm_dist_sum <- qap(edges, ideologies, nperm = n_qap_perm, cores = n_cores)
# 
# ## Linear model for mean aggregation (with qap standard errors)
# mean_score <- lm(log(mean_score) ~ ideology_dist, data = aggr)
# edges[, 3] <- aggr$mean_score
# perm_dist_mean <- qap(edges, ideologies, nperm = n_qap_perm, cores = n_cores)
# 
# ## Linear model for max aggregation (with qap standard errors)
# max_score <- lm(log(max_score) ~ ideology_dist, data = aggr)
# edges[, 3] <- aggr$max_score
# perm_dist_max <- qap(edges, ideologies, nperm = n_qap_perm, cores = n_cores)
# 
# ## Linear model for max aggregation (with qap standard errors)
# n_align <- lm(log(n_align) ~ ideology_dist, data = aggr)
# edges[, 3] <- aggr$n_align
# perm_dist_n_align <- qap(edges, ideologies, nperm = n_qap_perm, cores = n_cores)
# 
# 
# # ==============================================================================
# # Output results
# # ==============================================================================
# 
# # Table for regression results
# mods <- list(sum_score, mean_score, max_score, n_align)
# perms <- list(perm_dist_sum, perm_dist_mean, perm_dist_max, perm_dist_n_align)
# 
# res <- data.frame(Intercept = sapply(mods, function(x) x$coef[1]),
#                   Estimate = sapply(mods, function(x) x$coef[2]),
#                   Std.Error = sapply(perms, function(x) sqrt(var(x))))
#
# # Store results to disk
# save(list = c("res", "perms"), file = "qap_results.RData")

# Make latex results table
rownames(res) <- c("Sum", "Mean", "Max", "No. Alignments")
sink(file = '../../manuscript/tables/ideology_regs.tex')
xtable(res, digits = 3, caption = "Log-Linear models for alignment and euclidian distance in ideology. Standard errors are generated from quadratic assignment procedure with 1000 iterations. The rows correspond to different methods of aggregating the section alignments to bill allignments: \\textit{Sum}: Sum of alignment scores of all alignments, \\textit{Mean}: Average alignment score accross secion pairs bill dyad, \\textit{Max}: Highest alignment score seciton pairs of bill dyad, \\textit{No. Alignments}: Number of alignments for bill dyad.",
       label = "tab:ideology_regs")
sink()


# PLot distributions
n_qap_perm <- length(perms[[1]])
pdat <- data.frame(permutations = do.call(c, perms), 
                   aggregation = rep(c("Sum", "Mean", "Max", "# Alignments"), 
                                     each = n_qap_perm))

ests <- data.frame(aggregation = c("Sum", "Mean", "Max", "# Alignments"), 
                   beta = res$Estimate)

ggplot(pdat) + 
  geom_histogram(aes(permutations), color = "black", binwidth = 0.0005) + 
  geom_vline(data = ests, aes(xintercept = beta), color = "red") +
  facet_wrap(~ aggregation, scales = "fixed") +
  theme_bw()
ggsave('../../manuscript/figures/qap_dist.png')

### Old stuff

# Coefficient plot
pdat <- data_frame(model = as.factor(names(mods)), 
                   coefficient = sapply(mods, function(x) x$coef[2]),
                   std_error = sapply(mods, function(x) coef(summary(x))[2, 2])
                   ) %>% mutate(lower = coefficient - 2 * std_error, 
                                upper = coefficient + 2 * std_error)

ggplot(pdat) + 
    geom_point(aes(x = model, y = coefficient), color = "orange") +
    geom_errorbar(aes(x = model, ymax = upper, ymin = lower), width = 0.1) + 
    theme_bw() + 
    ylim(-0.05, 0.05)

#l ==============================================================================
# Some sanity checks
# ==============================================================================
