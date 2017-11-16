library(tidyverse)
library(igraph)

alignments <- read_csv('../../data/aligner_output/alignments_notext.csv') %>%
    select(-score, -lucene_score, -max_lucene_score) %>%
    rename(score = adjusted_alignment_score) %>%
    filter(!is.na(score))
metadata <- read_csv('../../data/bill_metadata.csv') %>%
    select(unique_id, date_last_action, date_passed_upper, date_passed_lower,
           chamber, bill_type) %>%
    mutate(passed = ifelse((!is.na(date_passed_lower) | 
                            !is.na(date_passed_lower)), TRUE, FALSE)) %>%
    select(unique_id, passed) 


# Calculate for each bill the total alignment score (i.e. how much shared text)
df <- group_by(alignments, left_id) %>% 
    summarize(average_alignment = mean(score, na.rm = TRUE),
              total_alignment = sum(score, na.rm = TRUE), 
              median_alignment = median(score, na.rm = TRUE),
              qant75 = quantile(score, 0.75),
              qant85 = quantile(score, 0.85),
              qant95 = quantile(score, 0.95),
              qant99 = quantile(score, 0.99),
              qant999 = quantile(score, 0.999),
              ) %>%

    # merge with the bill metadata
    left_join(metadata, by = c("left_id" = "unique_id")) %>% 
    gather(measure, score, -left_id, -passed) 
write_csv(df, file = 'per_bill_smry.csv')
stop()

ggplot(df) +
    geom_boxplot(aes(x = passed, y = score), outlier.size = 0.3, 
                 outlier.alpha = 0.2) +
    facet_wrap(~measure, scales = 'free') +
    scale_y_log10() +
    theme_bw()

summary(lm(score ~ passed, data = filter(df, measure == 'median_alignment')))

# Clustering

## Create the adjacency matrix
g <- graph.data.frame(alignments, directed = TRUE)
rm(alignments)
mat <- as_adjacency_matrix(g, type = "both", names = TRUE, sparse = FALSE,
                               attr = "score")

## Convert to distances
mat <- 1/(mat + min(mat[mat != 0]) / 2)

hcl <- hclust(as.dist(mat), method = 'single')
