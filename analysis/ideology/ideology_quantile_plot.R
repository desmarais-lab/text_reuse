library(ggplot2)
library(xtable)
library(quantreg)
library(dplyr)

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
load("../../data/alignments/ideology.RData")

## Descriptive scatterplot on sample of points
quantiles <- c(seq(0.5, 0.9, by = 0.1), seq(0.91, 0.99, by = 0.01), 0.999)

p <- ggplot(df, aes(x = ideology_dist, y = alignment_score)) + 
    stat_binhex() + 
    stat_quantile(quantiles = quantiles, color = cbPalette[6]) + 
    xlab("Ideological Distance") + 
    ylab("Alignment Score") + 
    scale_fill_gradient(low = "grey80", high = cbPalette[2]) +
    plot_theme
ggsave(plot = p, '../../4344753rddtnd/figures/ideology_quantile_plot.png', 
       width = p_width, height = 0.65 * p_width)

quant_reg <- function(q) {
    mod <- rq(alignment_score ~ ideology_dist, data = paggr, tau = q) 
    cat("done\n")
    return(mod) 
}
mods <- lapply(qs, quant_reg)
coefs <- sapply(mods, function(x) return(coef(x)[2]))
df <- data.frame(quantile = qs, coefficient = coefs)
df <- df[order(df$quantile, decreasing = FALSE), ]
xtable(df, digits = 3)