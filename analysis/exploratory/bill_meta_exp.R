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
    group_by(state) %>% 
    summarize(year_min = min(year_introduced, na.rm = TRUE),
              year_max = max(year_introduced, na.rm = TRUE),
              count = n())

regions <- data.frame(region = c(rep("Northeast", 9),
                                 rep("Midwest", 12),
                                 rep("South", 18),
                                 rep("West", 13)),
                      state = c("ct", "me", "ma", "nh", "ri", "vt", "nj", "ny",
                                "pa", "il", "in", "mi", "oh", "wi", "ia", "ks",
                                "mn", "mo", "ne", "nd", "sd", "de", "fl", "ga",
                                "md", "nc", "sc", "va", "dc", "wv", "al", "ky",
                                "ms", "tn", "ar", "la", "pr", "ok", "tx", "az", "co",
                                "id", "mt", "nv", "nm", "ut", "wy", "ak", "ca",
                                "hi", "or", "wa"))
regions <- regions[order(regions$state), ]
state_desc$region <- regions$region

## Plot all states
ggplot(state_desc) +
    geom_segment(aes(x = year_min, xend = year_max, y = seq(1,length(state)), 
                     yend = seq(1,length(state)), color = count), size = 2) + 
    theme_bw() + xlab("Year") + ylab("State") +
    scale_color_continuous(name = "# of Bils") + 
    guides(size = FALSE) +
ggsave('../../manuscript/figures/year_count_by_state.png')


