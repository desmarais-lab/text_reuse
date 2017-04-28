library(dplyr)

get_year <- function(x) as.integer(ifelse(x == "", NA, unlist(strsplit(x, '-'))[1]))

df <- read.csv('../../data/bill_metadata.csv', stringsAsFactors = FALSE) %>%
    select(unique_id, date_introduced, date_signed, state, chamber, bill_length,
           sponsor_idology, num_sponsors, short_title) %>%
    mutate(year_introduced = sapply(date_introduced, get_year),
           year_signed = sapply(date_signed, get_year),
           date_introduced = ifelse(date_introduced == "", NA, date_introduced),
           date_signed = ifelse(date_signed == "", NA, date_signed),
           sponsor_ideology = sponsor_idology,
           short_title = ifelse(short_title == "", NA, short_title)
           ) %>%
    select(-sponsor_idology) %>%
    distinct(unique_id, .keep_all = TRUE) %>%
    write.csv(file = 'metadata.csv', row.names = FALSE)
