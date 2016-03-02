library(ggplot2)
library(dplyr)

FIG_DIR <- '../../manuscript/figures/'
DATA <- '../../data/lid/alignment_timing.csv'

df <- tbl_df(read.csv(DATA, header = TRUE))

# Remove identical bill pairs
df <- filter(df, as.character(focus_bill) != as.character(right_bill))
df$total_length = df$left_bill_length + df$right_bill_lenght


ggplot(df[c(1:5000), ]) + geom_point(aes(x = log(right_bill_lenght), y = log(time),
                                     color = focus_bill, size = log(left_bill_length)),
                                     alpha = 0.3) + 
    guides(color = guide_legend(override = list(alpha = 1)),
           size = guide_legend(override = list(alpha = 1))) + 
    theme_bw()
ggsave(paste0(FIG_DIR, 'time_size_selection.png'))

ggplot(df) + geom_point(aes(x = log(right_bill_lenght), y = log(time),
                                   size = log(left_bill_length)),
                                   alpha = 0.1) + 
    guides(color = guide_legend(override = list(alpha = 1)),
           size = guide_legend(override = list(alpha = 1))) + 
    theme_bw()
ggsave(paste0(FIG_DIR, 'time_size_all.png'))

ggplot(df) + geom_histogram(aes(log(time)), color = 'white') + 
    theme_bw()
ggsave(paste0(FIG_DIR, 'time.png'))

ggplot(df) + geom_histogram(aes(log(alignment_length)), color = 'white') + 
    theme_bw()
ggsave(paste0(FIG_DIR, 'alignment_scores.png'))

ggplot(df) + geom_point(aes(y = log(score), x = log(alignment_length),
                            size = log(total_length)), alpha = 0.1)
ggsave(paste0(FIG_DIR, 'alignment_length_score.png'))

# Look at the states
