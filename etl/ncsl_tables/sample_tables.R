library(tidyverse)

urls <- read_csv('../../data/ncsl/checked_urls.csv')

# Selection criteria:
# - Comes from the query "site:ncsl.org "legislation.aspx""
# - Must be a ncsl topic table
# - Less than 100 bills on in the table
# - Must contain bills (not statutes or codes)
# - After 2011

# Select ursl from correct query
urls <- urls[grepl('legislation.aspx', urls$url), ]

# Load urls sampled in first iteration (have coding already) 
# this is how they were sampled:
#n <- 50 
#set.seed(82096)
#sampled_urls <- urls[sample(c(1:nrow(urls)), n), ]
sampled_first <- read_csv('../../data/ncsl/sampled_urls.csv')

# Get the remaining bills
remaining <- filter(urls, !is.element(id, sampled_first$id))

# Take a sample
set.seed(5921111)
sampled <- remaining[sample(1:nrow(remaining), 50), ] %>%
    select(-good, -size) %>%
    mutate(size = NA, is_table = NA, right_size = NA, after_2010 = NA)

out <- rbind(sampled_first, sampled)
write_csv(out, '../../data/ncsl/sampled_urls.csv')

# Coding of the sampled urls was done in a table editor
coded_urls <- read.csv('../../data/ncsl/sampled_urls.csv', header = TRUE, 
                       stringsAsFactors = FALSE)

coded_urls$all_conditions <- ifelse(coded_urls$is_table + coded_urls$right_size + 
    coded_urls$after_2010 == 3, 1, 0)

length(which(coded_urls$all_conditions == 1))
