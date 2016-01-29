
urls <- read.csv('../../data/ncsl/checked_urls.csv',
                 header = TRUE, stringsAsFactors = FALSE)

# Selection criteria:
# - Comes from the query "site:ncsl.org "legislation.aspx""
# - Must be a ncsl topic table
# - Less than 100 bills on in the table
# - Must contain bills (not statutes or codes)
# - After 2011

# Select ursl from correct query
urls <- urls[grepl('legislation.aspx', urls$url), ]


# Take a sample
n <- 50 # no of bills to sample
set.seed(82096)
sampled_urls <- urls[sample(c(1:nrow(urls)), n), ]
write.csv(sampled_urls, '../../data/ncsl/sampled_urls.csv', row.names = FALSE)

# Coding of the sampled urls was done in a table editor

coded_urls <- read.csv('../../data/ncsl/sampled_urls.csv', header = TRUE, 
                       stringsAsFactors = FALSE)

coded_urls$all_conditions <- ifelse(coded_urls$is_table + coded_urls$right_size + 
    coded_urls$after_2010 == 3, 1, 0)

length(which(coded_urls$all_conditions == 1))