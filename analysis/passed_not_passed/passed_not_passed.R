library(tidyverse)
library(igraph)
library(quantreg)

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


# Compare alignment scores of passed bills to not passed bills
df <- group_by(alignments, left_id) %>% 
    summarize(average_alignment = mean(score, na.rm = TRUE),
              total_alignment = sum(score, na.rm = TRUE), 
              median_alignment = median(score, na.rm = TRUE),
              maximum_alignment = max(score, na.rm = TRUE),
              quantile_99 = quantile(score, 0.99, na.rm = TRUE),
              quantile_95 = quantile(score, 0.95, na.rm = TRUE)
              ) %>% 
    # merge with the bill metadata
    left_join(metadata, by = c("left_id" = "unique_id"))
    
pdat <- df %>%
    gather(measure, score, -left_id, -passed) 

ggplot(pdat) +
    geom_boxplot(aes(x = passed, y = score), outlier.size = 0.3, 
                 outlier.alpha = 0.2) +
    facet_wrap(~measure, scales = 'free') +
    scale_y_log10() +
    theme_bw()

# Test for differences
avg_mod <- rq(average_alignment ~ passed, tau = 0.5, method = 'pfn', data = df)
tot_mod <- rq(total_alignment ~ passed, tau = 0.5, method = 'pfn', data = df)
med_mod <- rq(median_alignment ~ passed, tau = 0.5, method = 'pfn', data = df)
max_mod <- rq(maximum_alignment ~ passed, tau = 0.5, method = 'pfn', data = df)
q99_mod <- rq(quantile_99 ~ passed, tau = 0.5, method = 'pfn', data = df)
q95_mod <- rq(quantile_95 ~ passed, tau = 0.5, method = 'pfn', data = df)