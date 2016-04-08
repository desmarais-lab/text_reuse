library(dplyr)
library(ggplot2)

df <- tbl_df(read.csv(file = '../../data/bill_metadata.csv', header = TRUE,
                      stringsAsFactors = FALSE))

# Get bill prefixes
f <- function(x) return(x[length(x)])
df <- mutate(df, id = sapply(strsplit(unique_id, "_"), f),
             prefix = gsub("[[:digit:]-]", "", id))
    
prefixes <- group_by(df, state, prefix) %>% summarize(count = n())

# State distribution
state_desc <- mutate(df, date_introduced = as.Date(df$date_introduced)) %>%
    mutate(year_introduced = format(date_introduced, "%Y")) %>%
    group_by(state, year_introduced) %>% 
    summarize(count = n())


## Plot all states
ggplot(state_desc, aes(x=year_introduced, y=state)) + 
    geom_point(aes(size=count), color="#E69F00") + 
    geom_point(aes(size=count), shape=1, color="#999999") +
    theme_bw() + ylab("State") + xlab("Year")
ggsave('../../manuscript/figures/year_count_by_state.png')
