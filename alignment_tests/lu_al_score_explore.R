library(dplyr)
library(ggplot2)


df <- tbl_df(read.csv('../data/lid/lu_al_score_metadata.csv', header = TRUE,
                      stringsAsFactors = FALSE)) %>%
        mutate(focus_state = substr(focus_bill_id, 1,2), 
           right_state = substr(right_bill_id, 1,2),
           same_state = as.logical(ifelse(focus_state == right_state, T, F)),
           same_bill = as.logical(ifelse(focus_bill_id == right_bill_id, T, F))) 

# Get the closest 100 bills (lucene) and append indicator to df
df <- group_by(df, focus_bill_id, right_bill_id) %>% 
    summarize(lucene_score = mean(lucene_score)) %>%
    arrange(desc(lucene_score)) %>%
    group_by(focus_bill_id) %>%
    mutate(closest100 = ifelse(row_number(focus_bill_id) <= 100, 1, 0)) %>%
    select(right_bill_id, focus_bill_id, closest100) %>%
    right_join(df, by = c("right_bill_id" = "right_bill_id",
                          "focus_bill_id" = "focus_bill_id")) %>%
    ungroup()
    

df <- left_join(df, lucene_only, by = c("right_bill_id" = "right_bill_id",
                                       "focus_bill_id" = "focus_bill_id")) 


# Remove identical bill pairs (identical ids)
#df <- filter(df, focus_bill_id != right_bill_id)
#df_sample <- df[sample(c(1:nrow(df)), 10000), ]
#il_93rd_HB2871,il_93rd_HB2871,2380,2439,897.0,3.730505,19.1226098537,1.55033898354

# Plot some stuff

## Distributions
ggplot(df) + geom_histogram(aes(x = log(alignment_score)), color = 'white')
ggplot(df) + geom_histogram(aes(x = log(lucene_score)), color = 'white')

## Lucene score and alignment score for a sample
set.seed(5092903)
pdat <- filter(df, rownames(df) %in% sample(rownames(df), 1e5, replace = F))

ggplot(pdat) + 
    geom_point(aes(x = log(alignment_score), 
                   y = log(lucene_score), 
                   color = same_state,
                   shape = same_bill,
                   size = same_bill), 
                alpha = 0.7) +
    scale_colour_manual(values = c("#56B4E9", "#009E73")) + 
    theme_bw()
ggsave('../manuscript/figures/lu_al_scores.png') 


ggplot(pdat) + 
    geom_point(aes(x = log(alignment_score), 
                   y = log(lucene_score), 
                   color = as.factor(closest100),
                   shape = same_bill,
                   size = same_bill), 
               alpha = 0.7) +
    scale_colour_manual(values = c("#56B4E9", "#009E73")) + 
    theme_bw()
ggsave('../manuscript/figures/lu_al_scores.png') 

# Scores for 9 example bill
bills <- sample(df$focus_bill_id, 9, replace = FALSE)
pdat1 <- filter(df, focus_bill_id %in% bills)
  
ggplot(pdat1) + 
    facet_wrap(~ focus_bill_id) + 
    geom_point(aes(x = log(alignment_score), y = log(lucene_score),
                   color = as.factor(closest100), size = same_bill,
                   shape = same_bill), alpha = 0.6) + 
    scale_colour_manual(values = c("#56B4E9", "#009E73")) + 
    theme_bw()
ggsave('../manuscript/figures/closest100.png')

counts <- group_by(df, focus_bill_id) %>% 
    summarize(n_right_bills = length(unique(right_bill_id)),
              n_same_bill = sum(same_bill))
