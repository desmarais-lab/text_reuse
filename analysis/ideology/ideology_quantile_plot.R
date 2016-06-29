library(microbenchmark)
library(ggplot2)
library(dplyr)
library(quantreg)
library(xtable)

#Plotting parameters
source('../plot_theme.R')

# ==============================================================================
# Ideology plot
# ==============================================================================

# Load the data (see `ideology_preprocessing.R` for details)
cat('Loading data...\n')
load("../../data/ideology_analysis/ideology.RData")

#bak <- df
#df <- bak[sample(c(1:nrow(bak)), 1e6), ]
#df <- bak

## Descriptive scatterplot on sample of points
quantiles <- c(seq(0.5, 0.9, by = 0.1), seq(0.91, 0.99, by = 0.01), 
               seq(0.991, 0.995, by =0.001))

p <- ggplot(df, aes(x = ideology_dist, y = alignment_score)) + 
    stat_binhex(bins = 150) + 
    xlab("Ideological Distance") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = cbPalette[1], high = cbPalette[2], trans = "log",
                        labels = function (x) round(x, 0)) +
    guides(fill=guide_legend(title="Count")) +
    plot_theme
cat('Saving plot...\n')
ggsave(plot = p, '../../4344753rddtnd/figures/ideology_plot.png', 
       width = p_width, height = 0.65 * p_width)

p <- ggplot(df, aes(x = ideology_dist, y = alignment_score)) + 
    stat_binhex(bins = 300) + 
    stat_quantile(quantiles = quantiles, color = cbPalette[6], 
                  method.args = list("method" = "pfn")) + 
    xlab("Ideological Distance") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = cbPalette[1], high = cbPalette[2], trans = "log",
                        labels = function (x) round(x, 0)) +
    guides(fill=guide_legend(title="Count")) +
    plot_theme

cat('Saving plot...\n')
ggsave(plot = p, '../../4344753rddtnd/figures/ideology_quantile_plot.png', 
       width = p_width, height = 0.65 * p_width)
