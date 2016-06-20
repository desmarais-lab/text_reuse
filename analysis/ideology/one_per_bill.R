library(dplyr)
library(quantreg)


load("ideology_analysis.RData")
#aggr <- aggr[sample(c(1:nrow(aggr)), 1000, replace=FALSE), ]
# ==============================================================================
# Ideology quantile regressions
# ==============================================================================

# One model per bill
# ==============================================================================

#Remove left bills that don't have enough observations
n_obs <- group_by(aggr, left_doc_id) %>%
    summarize(n_bills = n())

aggr <- left_join(aggr, n_obs, by = "left_doc_id")
aggr <- filter(aggr, n_bills > 100)


# General model
new_rq <- function(y,x, tau) {
    return(coef(rq(y ~ x, tau = tau))[2])
}

regs <- group_by(aggr, left_doc_id) %>%
    summarize(
        #coef_med = new_rq(alignment_score, ideology_dist, 0.5),
        #coef_75 = new_rq(alignment_score, ideology_dist, 0.75),
        #coef_95 = new_rq(alignment_score, ideology_dist, 0.95),
        coef_99 = new_rq(alignment_score, ideology_dist, 0.99),
        #coef_99 = new_rq(alignment_score, ideology_dist, 0.999)
              )


# ggplot(regs) + 
#     geom_boxplot(aes(y = quant_coef))