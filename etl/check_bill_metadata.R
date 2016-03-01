library(dplyr)
library(ggplot2)

df <- read.csv('../data/bill_metadata.csv', stringsAsFactors = FALSE,
                      header = TRUE, quote = '"')

# THis one is constant
df$session <- NULL

# Make 'None' NA
df[df == 'None'] <- NA

# Fix column classes
for(i in grep("date_", names(df))){
    var <- sapply(as.character(df[, i]), substr, 1, 10)
    var
    df[, i] <- as.Date(x = var)
}

for(col in c("state", "chamber", "bill_type")){
    df[, col] <- as.factor(df[, col])
}
df$sponsor_idology <- as.numeric(df$sponsor_idology)
df$num_sponsors <- as.integer(df$num_sponsors)

df <- tbl_df(df)

# For how many bills do we have ideology estimates