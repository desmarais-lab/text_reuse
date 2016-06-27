# Regression on series of quantiles of the alignment score conditional on
# ideological distance of the bills

library(microbenchmark)
library(dplyr)
library(quantreg)

args <- commandArgs(trailingOnly = TRUE)

# Load the data (see ideology_preprocess.R)
cat("Loading data...\n")
load('../../data/alignments/ideology.RData')

quantiles <- c(seq(0.5, 0.9, by = 0.2), seq(0.91, 0.99, by = 0.02), 
               seq(0.991, 0.999, by =0.002))


bak <- df
df <- bak[c(1:10000), ]

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
    save(mods, file = paste0("quantreg_mods.RData"))
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
    
    save(out, file = paste0("bs_out_", no, ".RData"))   
} 