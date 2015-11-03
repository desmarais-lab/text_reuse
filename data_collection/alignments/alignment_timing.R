library(ggplot2)
library(dplyr)

df <- tbl_df(read.csv('../../data/lid/alignment_timing.csv', header = TRUE))

df <- filter(df, as.character(focus_bill) != as.character(right_bill))
# Remove identity bill pairs

df$total_length = df$left_bill_length + df$right_bill_lenght

ggplot(df[c(1:5000), ]) + geom_point(aes(x = log(right_bill_lenght), y = log(time),
                                     color = focus_bill, size = log(left_bill_length)),
                                     alpha = 0.3) + 
    guides(color = guide_legend(override = list(alpha = 1)),
           size = guide_legend(override = list(alpha = 1))) + 
    theme_bw()

ggplot(df) + geom_point(aes(x = log(right_bill_lenght), y = log(time),
                                   size = log(left_bill_length)),
                                   alpha = 0.1) + 
    guides(color = guide_legend(override = list(alpha = 1)),
           size = guide_legend(override = list(alpha = 1))) + 
    theme_bw()

ggplot(df) + geom_histogram(aes(log(time)), color = 'white') + 
    theme_bw()

ggplot(df) + geom_histogram(aes(log(alignment_length)), color = 'white') + 
    theme_bw()

ggplot(df) + geom_point(aes(y = log(score), x = log(alignment_length),
                            size = log(total_length)), alpha = 0.1)
