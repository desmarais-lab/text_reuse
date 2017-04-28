# Regression on series of quantiles of the alignment score conditional on
# ideological distance of the bills

library(dplyr)
library(quantreg)
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)

data_dir <- '../../data/ideology_analysis/'
res_dir <- paste0(data_dir, 'bootstrap_results/')
quantiles <- c(seq(0.5, 0.9, by = 0.1), seq(0.91, 0.97, by = 0.01))

if(length(args) > 0) {
    
    # Generate bootstrap data 
    # Load the data (see ideology_preprocess.R)
    cat("Loading data...\n")
    load('../../data/ideology_analysis/ideology_analysis_input.RData')
    
    # Regression with clustered bootstrap
    
    # Fit primary regression model for all quantiles
    quant_reg <- function(q, dat) {
        mod <- rq(adjusted_alignment_score ~ ideology_dist, data = dat, tau = q,
                  method = "pfn")
        cat(paste0("Done with ", q, "\n"))
        return(mod)
    }
    
        
    if(args[1] == "base") {
        mods <- lapply(quantiles, quant_reg, dat = df)
        mods <- lapply(mods, coef)    
        save(mods, file = paste0(res_dir, "quantreg_mods.RData"))
    } else if(args[1] == "bootstrap") {
        
        # Uncertainty using the bootstrap
        no <- as.integer(args[2])
        B <- as.integer(args[3])
        
        clusters <- unique(df$left_id)
        nc <- length(clusters)
        out <- vector(mode = "list", length = B)
        
        for(i in 1:B) {
            
            # Sample clusters and build iteration-dataset
            sc <- sample(clusters, nc, replace = TRUE)
            dat <- filter(df, is.element(left_id, sc))
            
            # fit models 
            mods <- lapply(quantiles, quant_reg, dat = dat)
            mods <- lapply(mods, coef)
         
            out[[i]] <- mods
            cat(paste0("Finished iteration ", i, "\n"))
            cat(paste0("Size: ", nrow(dat), "\n"))
        }
        
        save(out, file = paste0(res_dir, "bs_out_", 
                                no, ".RData"))   
    } else {
        stop('Invalid mode argument')
    }

} else {

    # Process the bootstrap resutls and store results to file so not 
    # everything has to be donwnloaded from server
    out_files <- list.files(path = res_dir, 
                            pattern = "bs_out_")
    print(length(out_files) )
    outputs <- vector(mode = "list", length = length(out_files))
    
    i <- 1
    for(file in out_files) {
        load(paste0(res_dir, file))
        op <- sapply(out, function(x) do.call(cbind, x)[2, ])
        outputs[[i]] <- op

        i <- i + 1
        print(paste('Processed', file))
    }

    final_out <- do.call(cbind, outputs)

    load(paste0(res_dir, "quantreg_mods.RData"))
    base_model_coefs <- sapply(mods, function(x) x[2])

    print(dim(final_out))

    out <- list("bootstrap_results" = final_out, "base_model" = base_model_coefs)
    save(out, file = paste0(data_dir, "regression_results.RData"))
}

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
    ggplot(filter(pdat, quantile < 0.98)) +
        geom_segment(aes(x = quantile_fctr, xend = quantile_fctr, y = lower, 
                         yend = upper), size = 1) +
        geom_point(aes(x = quantile_fctr, y = coefs), size = 3) +
        scale_color_manual(values = c(cbPalette[1], "black")) +
        guides(color = FALSE) +
        geom_hline(aes(yintercept = 0), linetype = 2, color = "grey") + 
        coord_flip() + ylab("Quantile Regression Coefficient") +
        xlab("Quantile") + plot_theme
    ggsave('../../paper/figures/quantile_regression.png', width = p_width,
           height = 0.8 * p_width)
}

