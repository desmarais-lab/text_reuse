# Regression on series of quantiles of the alignment score conditional on
# ideological distance of the bills

library(dplyr)
library(quantreg)
library(ggplot2)
library(doParallel)

data_dir <- '../../data/ideology_analysis/'
quantiles <- c(seq(0.5, 0.9, by = 0.1), seq(0.91, 0.99, by = 0.01), 
               seq(0.991, 0.995, by =0.001))

# Load the data (see ideology_preprocess.R)
cat("Loading data...\n")
load('../../data/ideology_analysis/ideology_analysis_input.RData')

# Regression with clustered bootstrap
cat("Fit primary regression model for all quantiles...\n")
quant_reg <- function(q, dat) {
    mod <- rq(adjusted_alignment_score ~ ideology_dist, data = dat, tau = q,
              method = "pfn")
    cat(paste0("Done with ", q, "\n"))
    return(mod)
}

mods <- lapply(quantiles, quant_reg, dat = df)
mods <- lapply(mods, coef)    
base_model_coefs <- sapply(mods, function(x) x[2])

cat("Bootstrapping...\n")

B <- 100

clusters <- unique(df$left_id)
nc <- length(clusters)

bs_iter <- function(i) {
    # Sample clusters and build iteration-dataset
    sc <- sample(clusters, nc, replace = TRUE)
    dat <- filter(df, is.element(left_id, sc))
    
    # fit models 
    mods <- lapply(quantiles, quant_reg, dat = dat)
    return(lapply(mods, coef))
}

cl <- makeCluster(10)
registerDoParallel(cl)

out <- foreach(i=1:B, .packages = c("dplyr", "quantreg")) %dopar% bs_iter(i)

final_out <- sapply(out, function(x) do.call(cbind, x)[2, ])

out <- list("bootstrap_results" = final_out, "base_model" = base_model_coefs)
save(out, file = paste0(data_dir, "regression_results.RData"))

INTERACTIVE = FALSE

if(INTERACTIVE) {
    # Analyze results interactively
    load(paste0(data_dir, "regression_results.RData"))
    
    # Make coefficient plot
    pdat <- tbl_df(data.frame(coefs = out$base_model,
                              quantile = quantiles,
                              upper = apply(out$bootstrap_results, 1, quantile, 0.975),
                              lower = apply(out$bootstrap_results, 1, quantile, 0.025)
                              )
                   ) %>%
        mutate(quantile_fctr = as.factor(quantile),
               significant = as.factor(ifelse(upper < 0, 1, 0)))
    
    
    source('../plot_theme.R')
    ggplot(pdat) +
        geom_point(aes(x = quantile_fctr, y = coefs, color = significant)) +
        geom_segment(aes(x = quantile_fctr, xend = quantile_fctr, y = lower, 
                         yend = upper, color = significant)) +
        scale_color_manual(values = c(cbPalette[1], "black")) +
        guides(color = FALSE) +
        geom_hline(aes(yintercept = 0), linetype = 2, color = "grey") + 
        coord_flip() + ylab("Quantile Regression Coefficient") +
        xlab("Quantile") + plot_theme
    ggsave('../../manuscript/figures/quantile_regression.png', width = p_width,
           height = 0.8 * p_width)
}

