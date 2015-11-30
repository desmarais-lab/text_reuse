library(dplyr)
library(ggplot2)
library(lme4)
library(stargazer)

# ==============================================================================
# Data preprocessing
# ==============================================================================

# Metadata
meta <- read.csv('../../data/bill_metadata.csv', stringsAsFactors = FALSE,
                 header = TRUE, quote = '"')

## Clean it up
meta$session <- NULL
### Make 'None' NA
meta[meta == 'None'] <- NA
### Fix column classes
for(i in grep("date_", names(meta))){
    var <- sapply(as.character(meta[, i]), substr, 1, 10)
    var
    meta[, i] <- as.Date(x = var)
}
for(col in c("state", "chamber", "bill_type")){
    meta[, col] <- as.factor(meta[, col])
}
meta$sponsor_idology <- as.numeric(meta$sponsor_idology)
meta$num_sponsors <- as.integer(meta$num_sponsors)

## Make dplyr object
meta <- tbl_df(meta)

# Alignments
alignments <- tbl_df(read.csv('../../data/lid/bill_to_bill_scores_only.csv', 
                              colClasses = c("factor", "factor", "numeric"),
                              skip = 1) )

## Match alignments with ideology scores
temp <- mutate(meta, left_doc_id = unique_id, left_ideology = sponsor_idology) %>%
    select(left_doc_id, left_ideology)
df <- left_join(alignments, temp, by = "left_doc_id")
temp <- mutate(meta, right_doc_id = unique_id, right_ideology = sponsor_idology) %>%
    select(right_doc_id, right_ideology)
df <- left_join(df, temp, by = "right_doc_id")
rm(temp)
df <- mutate(df, ideology_dist = (left_ideology - right_ideology)^2,
             dyad_id = as.factor(paste0(left_doc_id, right_doc_id)))
df_nona <- filter(df, !is.na(ideology_dist))

## Aggregate to bill level
penal_mean <- function(x) sum(x) / exp(length(x) - 1)
aggr <- group_by(df, left_doc_id, right_doc_id) %>%
    summarize(sum_score = sum(alignment_score), n_align = n(),
              mean_score = mean(alignment_score), 
              penal_score = penal_mean(alignment_score),
              max_score = max(alignment_score),
              ideology_dist = ideology_dist[1])

# ==============================================================================
# Descriptives
# ==============================================================================

# Number of bills with ideology scores
length(which(!is.na(meta$sponsor_idology))) / nrow(meta)

# Number of dyads with ideology distance
length(which(!is.na(aggr$ideology_dist))) / nrow(aggr)

# Distribution of distance and log(score)
ggplot(aggr) + geom_histogram(aes(ideology_dist), color = "white")

# ==============================================================================
# Analyses
# ==============================================================================

# Regression on section level

## Linear Model
mod_sec <- lm(log(alignment_score) ~ ideology_dist, data = df_nona)
summary(mod_sec)

### Diagnostic Plots
ggplot(df_nona) + geom_histogram(aes(log(alignment_score)), color = "white")
res_samp <- sample(residuals(mod_sec), 1e5)
ggplot() + geom_point(aes(x = c(1:length(res_samp)), y = res_samp), size = 1,
                      alpha = 0.6) + theme_bw()

ggplot(samp) + geom_point(aes(x = ideology_dist, y = log(alignment_score)), 
                             alpha = 0.1) + 
    theme_bw() + 
    geom_smooth(aes(x = ideology_dist, y = log(alignment_score)))

## Linear mixed effects model -- doesn't work
#mmod_sec <- lmer(log(alignment_score) ~ ideology_dist + (1 | dyad_id),
#                 data = df_nona)


# Models on bill level
mods <- list(
    sum_score = lm(log(sum_score) ~ ideology_dist, data = aggr),
    n_align = lm(log(n_align) ~ ideology_dist, data = aggr),
    mean_score = lm(log(mean_score) ~ ideology_dist, data = aggr),
    penal_score = lm(log(penal_score) ~ ideology_dist, data = aggr),
    max_score = lm(log(max_score) ~ ideology_dist, data = aggr)
)

# ==============================================================================
# Output results
# ==============================================================================

# Overview table
stargazer(mod_sec, mods,
          out = '../../manuscript/tables/ideology_regressions.tex',
          #column.labels = c("Sections", "Bills"),
          column.separate = c(1, 5),
          dep.var.labels = c("Score", "Sum", "Number", "Mean", "Penal", "Max"),
          keep.stat = c("n", "adj.rsq"),
          label = "tab:ideo_reg",
          title = c("Regression results for log-linear models for ideology 
                    analysis. The models from left to right: 1) Alignment score 
                    by section (dependence not considered yet), 
                    2) Sum of alignment scores of all sections of
                    bill dyads, 3) Number of alignments of bill dyad, 4) 
                    mean alignment score of dyad, 5) penalized mean alignment 
                    score of dyad, 5) maximum alignment score of dyad. ")
          )

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
