library(microbenchmark)
library(ggplot2)
library(dplyr)
library(quantreg)
library(xtable)

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


bak <- df
df <- bak[sample(c(1:nrow(bak)), 1e6), ]
df <- bak

## Descriptive scatterplot on sample of points
quantiles <- c(seq(0.5, 0.9, by = 0.1), seq(0.91, 0.99, by = 0.01), 0.999)


p <- ggplot(df, aes(x = ideology_dist, y = alignment_score)) + 
    stat_binhex(bins = 100) + 
    #stat_quantile(quantiles = quantiles, color = cbPalette[6], 
    #              method.args = list("method" = "pfn")) + 
    xlab("Ideological Distance") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = "grey90", high = cbPalette[2]) +
    plot_theme

cat('Saving plot...\n')
ggsave(plot = p, '../../4344753rddtnd/figures/ideology_plot.png', 
       width = p_width, height = 0.65 * p_width)

p <- ggplot(df, aes(x = ideology_dist, y = alignment_score)) + 
    stat_binhex() + 
    stat_quantile(quantiles = quantiles, color = cbPalette[6], 
                  method.args = list("method" = "pfn")) + 
    xlab("Ideological Distance") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = "grey80", high = cbPalette[2],
                        breaks = c(0, 12.5e6, 2.5e7)) +
    plot_theme
cat('Saving plot...\n')
ggsave(plot = p, '../../4344753rddtnd/figures/ideology_quantile_plot.png', 
       width = p_width, height = 0.65 * p_width)