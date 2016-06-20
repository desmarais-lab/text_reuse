library(dplyr)
library(quantreg)
library(ggplot2)
library(xtable)


load("ideology_analysis.RData")
#aggr <- aggr[sample(c(1:nrow(aggr)), 1000, replace=FALSE), ]
p_width <- 8
# ==============================================================================
# Ideology quantile regressions
# ==============================================================================

# One model per bill
# ==============================================================================

#Remove left bills that don't have enough observations
n_obs <- group_by(aggr, left_doc_id) %>%
    summarize(n_bills = n())

aggr <- left_join(aggr, n_obs, by = "left_doc_id")
aggr <- filter(aggr, n_bills > 10 & n_bills < 1000)
aggr

# General model
new_rq <- function(y,x, tau) {
    return(coef(rq(y ~ x, tau = tau))[2])
}

regs <- group_by(aggr, left_doc_id) %>%
    summarize(
        #coef_med = new_rq(alignment_score, ideology_dist, 0.5),
        #coef_75 = new_rq(alignment_score, ideology_dist, 0.75)
        coefs = new_rq(alignment_score, ideology_dist, 0.999)
        #coef_99 = new_rq(alignment_score, ideology_dist, 0.99)
        #coef_99 = new_rq(alignment_score, ideology_dist, 0.999)
              )

regs <- left_join(regs, n_obs, by = "left_doc_id")
ggplot(regs) + 
    geom_point(aes(y=coefs, x = n_bills), size = 0.5, alpha = 0.2) + 
     
    theme_bw() + ylim(-1, 1)
ggsave('../../4344753rddtnd/figures/ideology_regressions_cut.png',
       width = p_width, height = 0.65 * p_width)
ggplot(regs) + 
    geom_point(aes(y=coefs, x = n_bills), size = 0.5, alpha = 0.2) + 
    theme_bw()
ggsave('../../4344753rddtnd/figures/ideology_regressions.png',
       width = p_width, height = 0.65 * p_width)


sink('../../4344753rddtnd/tables/ideology_regressions.tex')
xtable(as.matrix(summary(regs$coef_95)), 
       caption = "Summary statistics for distribution of coefficients for 0.95th 
       quantile regression",
       label = "tab:ideology_regressions",
       digits = 3)
sink()

