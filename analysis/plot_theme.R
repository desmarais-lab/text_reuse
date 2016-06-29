# Style for all plots in this paper

cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
               "#D55E00", "#CC79A7")
p_width <- 18.9

plot_theme <- theme(axis.text=element_text(size=12),
                    axis.title=element_text(size=14), legend.text=element_text(size=12)) +
    theme_bw()
