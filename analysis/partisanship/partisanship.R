library(tidyverse)
library(igraph)
library(quantreg)
library(xtable)
library(data.table)
source('../plot_theme.R')

# Load ideology data
load("../../data/ideology_analysis/ideology_analysis_input.RData")
df <- data.table(df)

# Proportion of scores > value 
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
df$dyad_type <- paste(df$left_party, df$right_party, sep = "_")
setkey(df, dyad_type)
df <- df[c("D_D", "R_R"), c("adjusted_alignment_score", "dyad_type", "left_id"), 
         nomatch=0]

hm <- function(score, threshold) {
    prop <- sum(score > threshold) / length(score)
    #prop <- sum(score > threshold)
    return(round(prop * 100, 6))
}

# Bootstrap the quantiles
bs_quantiles <- function(i, data, ids, full=FALSE) {
    if(full) bs_sample <- sample(ids, length(ids), replace = FALSE) 
    else bs_sample <- sample(ids, length(ids), replace = TRUE) 
    out <- data[CJ(c("D_D", "R_R"), bs_sample), 
                .('gt_10' = hm(adjusted_alignment_score, 10),
                 'gt_100' = hm(adjusted_alignment_score, 100),
                 'gt_1000' = hm(adjusted_alignment_score, 1000),
                 'gt_5000' = hm(adjusted_alignment_score, 5000),
                 'gt_7000' = hm(adjusted_alignment_score, 7000)
                 ), 
                 by=.(dyad_type), nomatch=0]
    return(out)
}

setkey(df, dyad_type, left_id)
ids <- unique(df$left_id)

# Get the full sample values
out <- bs_quantiles(1, df, ids, TRUE)

## Transform to table format we want in the paper
tab <- tbl_df(t(out))[-1, ] %>% mutate(D_D = as.numeric(V1),
                                       R_R = as.numeric(V2)) %>%
    select(-V1, -V2)
tab$ratio <- tab$D_D / tab$R_R

# Bootstrap confidence intervals for the ratio
B <- 1000
bs_out <- lapply(1:B, bs_quantiles, df, ids, FALSE)
save(bs_out, file = 'bootstrap_results.RData')

## Generate ratio for each bs iteration
ratios <- lapply(bs_out, function(x) x[dyad_type == "D_D", 2:6] / 
                                     x[dyad_type == "R_R", 2:6])
ratios <- tbl_df(do.call(rbind, ratios))
cis <- apply(ratios, 2, quantile, c(0.025, 0.975))

## Joint to output table
tab <- cbind(tab, t(cis))

## Make latex table
rownames(tab) <- paste0('% > ', c(10, 100, 1000, 5000, 7000))
colnames(tab) <- c("Democratic", "Republican", "Ratio D/R", "CI low", "CI high")
tab_ltx <- xtable(tab, caption = paste("Distribution of bill scores by party",
                                       "dyad. 95\\% confidence intervals based on", 
                                        B , "bootstrap iteration clustered",
                                       "on left bill id."),
       label = 'tab:dyad_distribution', digits = 4)
print(tab_ltx, file = '../../paper/tables/partisanship_dyad_distribution.tex')

# Check bill lenght by party
bills <- fread('../../data/bill_metadata.csv')
setkey(bills, primary_sponsor_party)
bills[, .("length" = mean(bill_length)), by=primary_sponsor_party]
    

# Plot Distribution of alignment scores
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
r <- range(df$adjusted_alignment_score)
thresholds <- exp(seq(log(r[1]), log(r[2]), length.out = 100))

hm <- function(threshold, data) {
    prop <- sum(data$adjusted_alignment_score > threshold) / nrow(df)
    return(prop)
}

setkey(df, dyad_type)
cumdist_DD <- do.call(rbind, lapply(thresholds, hm, df["D_D", ]))
cumdist_RR <- do.call(rbind, lapply(thresholds, hm, df["R_R", ]))

pdat <- data_frame(Proportion = c(cumdist_DD, cumdist_RR),
                   Party = rep(c("D_D", "R_R"), each = length(thresholds)),
                   Score = rep(thresholds, 2))
ggplot(pdat) + 
    geom_line(aes(x = Score, y = Proportion, color = Party, linetype = Party)) +
    scale_y_log10() + plot_theme + scale_color_manual(values = cbPalette)
ggsave('../../paper/figures/partisanship_score_distribution.png')