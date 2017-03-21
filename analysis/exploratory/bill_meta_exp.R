library(dplyr)
library(ggplot2)

source('../plot_theme.R')

# Load original sunlight bill metadata
full_meta <- tbl_df(read.csv(file = '../../data/bill_metadata.csv', header = TRUE,
                      stringsAsFactors = FALSE))

# Load the list of bills in the database (only bills with text available)
bill_list <- tbl_df(read.csv(file = '../../data/bill_ids.txt', 
                             stringsAsFactors = FALSE, header = FALSE))
colnames(bill_list) <- c("unique_id")

df <- left_join(bill_list, full_meta)

# Get bill prefixes and introduction years
f <- function(x) return(x[length(x)])
df <- mutate(df, id = sapply(strsplit(unique_id, "_"), f),
              prefix = gsub("[[:digit:]-]", "", id),
              date_introduced = as.Date(df$date_introduced),
              year_introduced = format(date_introduced, "%Y"),
              bill_length = as.integer(bill_length)
              )
prefixes <- group_by(df, state, prefix) %>% summarize(count = n())
coverage <- group_by(df, state, year_introduced) %>% summarize(count = n())
#write.csv(coverage, '../../data/lid/nbills_by_state.csv', row.names = FALSE)
#coverage <- tbl_df(read.csv('../../data/lid/nbills_by_state.csv', 
#                            stringsAsFactors = FALSE))

# State distribution bill counts
state_desc <- mutate(df, date_introduced = as.Date(df$date_introduced)) %>%
    mutate(year_introduced = format(date_introduced, "%Y")) %>%
    group_by(state, year_introduced) %>% 
    summarize(count = n())
#
## Plot all states
ggplot(state_desc, aes(x=year_introduced, y=state)) + 
    geom_point(aes(size=count), color=cbPalette[2]) + 
    #geom_point(aes(size=count), shape=1, color=cbPalette[3]) +
    ylab("State") + xlab("Year") + 
    guides(size=guide_legend(title="Count")) +
    plot_theme
ggsave('../../manuscript/figures/year_count_by_state.png', width = p_width,
       height = 0.7*p_width)

## Amount of text by state
# amount <- mutate(df, date_introduced = as.Date(df$date_introduced)) %>%
#     mutate(year_introduced = format(date_introduced, "%Y")) %>%
#     group_by(state) %>% 
#     summarize(count = n(),
#     text_amount = sum(bill_length, na.rm = TRUE))
# #
# ggplot(amount) + geom_bar(aes(x=state, y=text_amount/1e6), stat="identity") +
#     theme_bw() + theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
#     ylab("Amount of text (million words)") + xlab("State") + coord_flip()
# ggsave('../../4344753rddtnd/figures/text_amount.png')
