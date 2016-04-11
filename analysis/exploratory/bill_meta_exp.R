library(dplyr)
library(ggplot2)

df <- tbl_df(read.csv(file = '../../data/bill_metadata.csv', header = TRUE,
                      stringsAsFactors = FALSE))

df$bill_length <- ifelse(df$bill_length=="None", NA, as.integer(df$bill_length))

nrow(df)
df <- df[!is.na(df$bill_length), ]

# Get bill prefixes
f <- function(x) return(x[length(x)])
df <- mutate(df, id = sapply(strsplit(unique_id, "_"), f),
             prefix = gsub("[[:digit:]-]", "", id))
    
prefixes <- group_by(df, state, prefix) %>% summarize(count = n())

# State distribution bill counts
state_desc <- mutate(df, date_introduced = as.Date(df$date_introduced)) %>%
    mutate(year_introduced = format(date_introduced, "%Y")) %>%
    group_by(state, year_introduced) %>% 
    summarize(count = n())
#
## Plot all states
ggplot(state_desc, aes(x=year_introduced, y=state)) + 
    geom_point(aes(size=count), color="#E69F00") + 
    geom_point(aes(size=count), shape=1, color="#999999") +g
    theme_bw() + ylab("State") + xlab("Year")
ggsave('../../4344753rddtnd/figures/year_count_by_state.png')


## Amount of text by state
amount <- mutate(df, date_introduced = as.Date(df$date_introduced)) %>%
    mutate(year_introduced = format(date_introduced, "%Y")) %>%
    group_by(state) %>% 
    summarize(count = n(),
              text_amount = sum(bill_length, na.rm = TRUE))

ggplot(amount) + geom_bar(aes(x=state, y=text_amount/1e6), stat="identity") +
    theme_bw() + theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ylab("Amount of text (million words)") + xlab("State") + coord_flip()
ggsave('../../4344753rddtnd/figures/text_amount.png')
