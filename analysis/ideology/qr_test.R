library(ggplot2)
library(dplyr)
library(quantreg)
library(xtable)
library(microbenchmark)

#Plotting parameters
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
               "#D55E00", "#CC79A7")
p_width <- 11.5

plot_theme <- theme(axis.text=element_text(size=12), 
                    axis.title=element_text(size=14), legend.text=element_text(size=12)) +
    theme_bw() 
# ==============================================================================
# Ideology plot
# ==============================================================================

# Load the data (see `ideology_preprocessing.R` for details)
cat('Loading data...\n')
load("../../data/alignments/ideology.RData")


quant_reg <- function(q) {
    mod <- rq(alignment_score ~ ideology_dist, data = df, tau = q, method = "pfn") 
    cat("done\n")
    return(mod) 
}

cat('Fitting model...\n')
t1 <- microbenchmark(
    mod <- quant_reg(0.95),
    times = 1
)

print(t1)
print(summary(mod))
