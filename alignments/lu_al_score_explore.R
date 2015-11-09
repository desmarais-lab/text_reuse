library(dplyr)
library(ggplot2)


df <- tbl_df(read.csv('../data/lid/lu_al_score_metadata.csv', header = TRUE,
                      stringsAsFactors = FALSE))
df_sample <- df[sample(c(1:nrow(df)), 10000), ]
#il_93rd_HB2871,il_93rd_HB2871,2380,2439,897.0,3.730505,19.1226098537,1.55033898354

# Plot some stuff

## Distributions
ggplot(df) + geom_histogram(aes(x = log(alignment_score)), color = 'white')
ggplot(df) + geom_histogram(aes(x = log(lucene_score)), color = 'white')

## Lucene score and alignment score
pdat <- filter(df, focus_bill_id == unique(df$focus_bill_id)[4])
pdat$focus_state <- substr(pdat$focus_bill_id, 1,2)
pdat$right_state <- substr(pdat$right_bill_id, 1,2)
pdat$same_state <- pdat$focus_state == pdat$right_state
ggplot(pdat) + geom_point(aes(x = log(alignment_score), 
                              y = log(lucene_score), 
                              color = same_state), 
                              alpha = 0.5)
