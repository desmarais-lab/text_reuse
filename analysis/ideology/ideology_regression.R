# Regression on series of quantiles of the alignment score conditional on
# ideological distance of the bills

list.of.packages <- c("dplyr", "quantreg")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) {
    print(new.packages)
    print(R.version())
    print(.libPaths())
}


library(microbenchmark)
library(dplyr)
library(quantreg)
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)

data_dir <- '../../data/ideology_analysis/'
res_dir <- paste0(data_dir, 'bootstrap_results/')
quantiles <- c(seq(0.5, 0.9, by = 0.1), seq(0.91, 0.99, by = 0.01), 
               seq(0.991, 0.995, by =0.001))
#quantiles <- c(0.95)

if(length(args) > 0) {


    
    # Generate bootstrap data 
    # Load the data (see ideology_preprocess.R)
    cat("Loading data...\n")
    load(paste0(data_dir, 'ideology.RData'))
    
   
    #bak <- df
    #df <- bak[c(1:10000), ]
    
    # Regression with clustered bootstrap
    
    # Fit primary regression model for all quantiles
    quant_reg <- function(q, dat) {
        mod <- rq(alignment_score ~ ideology_dist, data = dat, tau = q, method = "pfn")
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
        
        clusters <- unique(df$left_doc_id)
        nc <- length(clusters)
        out <- vector(mode = "list", length = B)
        
        for(i in 1:B) {
            
            # Sample clusters and build iteration-dataset
            sc <- sample(clusters, nc, replace = TRUE)
            dat <- filter(df, is.element(left_doc_id, sc))
            
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
        print(i)
    }

    final_out <- do.call(cbind, outputs)

    load(paste0(res_dir, "quantreg_mods.RData"))
    base_model_coefs <- sapply(mods, function(x) x[2])

    out <- list("bootstrap_results" = final_out, "base_model" = base_model_coefs)
    save(out, file = paste0(data_dir, "regression_results.RData"))
    print(dim(final_out))

}

# Stop here if run from commandline
stop("")

# Analyze results interactively
load(paste0(data_dir, "regression_results.RData"))

# Make coefficient plot
pdat <- tbl_df(data.frame(coefs = out$base_model,
                          quantile = quantiles,
                          upper = apply(out$bootstrap_results, 1, quantile, 0.975),
                          lower = apply(out$bootstrap_results, 1, quantile, 0.025)
                          )
               ) %>%
    mutate(quantile_fctr = as.factor(quantile))

source('../plot_theme.R')
ggplot(pdat) +
    geom_point(aes(x = quantile_fctr, y = coefs)) +
    geom_segment(aes(x = quantile_fctr, xend = quantile_fctr, y = lower, yend = upper)) +
    coord_flip() + ylab("Quantile Regression Coefficient") +
    xlab("Quantile") + plot_theme
ggsave('../../4344753rddtnd/figures/quantile_regression.png', width = p_width,
       height = 0.8 * p_width)
