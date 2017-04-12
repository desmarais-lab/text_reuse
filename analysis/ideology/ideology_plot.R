library(ggplot2)
library(dplyr)
library(xtable)

#Plotting parameters
source('../plot_theme.R')

# ==============================================================================
# Ideology plot
# ==============================================================================

# Load the data (see `ideology_preprocessing.R` for details)
cat('Loading data...\n')
load('../../data/ideology_analysis/ideology_analysis_input.RData')

#bak <- df
#df <- bak[sample(c(1:nrow(bak)), 1e6), ]
#df <- bak

# Descriptive scatterplot on sample of points

## ALignments on natural scale
p <- ggplot(df, aes(x = ideology_dist, y = adjusted_alignment_score)) + 
    stat_binhex(bins = 80) + 
    xlab("Ideological Distance") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = "grey60", high = "grey1", trans = "log",
                        labels = function (x) round(x, 0)) +
    guides(fill=guide_legend(title="Count")) +
    plot_theme
cat('Saving plot...\n')
ggsave(plot = p, '../../paper/figures/ideology_plot.png', 
       width = p_width, height = 0.65 * p_width)

## Alignments on log scale
p <- p + scale_y_log10() + ylab("Log Alignment Score")
cat('Saving plot...\n')
ggsave(plot = p, '../../paper/figures/ideology_plot_log.png', 
       width = p_width, height = 0.65 * p_width)
