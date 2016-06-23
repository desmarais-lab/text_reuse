library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
SMALL <- as.logical(args[1])

# ==============================================================================
# Data preprocessing for ideology analysis
# ==============================================================================

# Load metadata
cat("Loading metadata...\n")
meta <- read.csv('../../data/lid/bill_metadata.csv', stringsAsFactors = FALSE,
                 header = TRUE, quote = '"')

## Clean it up
meta$session <- NULL
### Make 'None' NA
meta[meta == 'None'] <- NA
### Fix column classes
for(i in grep("date_", names(meta))){
    var <- sapply(as.character(meta[, i]), substr, 1, 10)
    meta[, i] <- as.Date(x = var)
}
for(col in c("state", "chamber", "bill_type")){
    meta[, col] <- as.factor(meta[, col])
}
meta$sponsor_idology <- as.numeric(meta$sponsor_idology)
meta$num_sponsors <- as.integer(meta$num_sponsors)
meta$bill_length <- as.integer(meta$bill_length)

## Make dplyr object
meta <- tbl_df(meta)

# Alignments
# 1000
cat("Loading alignment data...\n")
if(SMALL) {
    alignments <- tbl_df(read.csv('../../data/lid/alignments_1000_b2b_ns.csv', 
                         header = TRUE, stringsAsFactors = FALSE, nrows = 50000))
} else {
    alignments <- tbl_df(read.csv('../../data/lid/alignments_1000_b2b_ns.csv', 
                         header = TRUE, stringsAsFactors = FALSE))

}
## Match alignments with ideology scores and document length
### Join info on left bill
cat("Joining datasets...\n")
temp <- mutate(meta, left_doc_id = unique_id, left_ideology = sponsor_idology,
               left_length = bill_length) %>%
    dplyr::select(left_doc_id, left_ideology, left_length)
df <- left_join(alignments, temp, by = "left_doc_id")

### Join info on right bill
temp <- mutate(meta, right_doc_id = unique_id, right_ideology = sponsor_idology,
               right_length = bill_length) %>%
    dplyr::select(right_doc_id, right_ideology, right_length)
df <- left_join(df, temp, by = "right_doc_id")

# Calculate ideological distance and combined doc length
df <- mutate(df, ideology_dist = (left_ideology - right_ideology)^2)


# Write descriptives
n <- nrow(df)
cat(paste0("Preprocessed data from ", n, " bill dyads.\n"))
df <- filter(df, !is.na(ideology_dist))
m <- nrow(df)
cat(paste0((1 - m / n), "% of dyads missing ideological distance.\n"))
cat(paste0(m, " valid dyads from ", length(unique(df$left_doc_id)), 
           " left bills and ", length(unique(df$right_doc_id)), 
           " right bills remaining.\n"))


# Save R data obj 
ifelse(SMALL, fname <- "../../data/alignments/ideology_small.RData",
       "../../data/alignments/ideology.R")
cat(paste0("Saving to ", fname, "\n"))
save(df, file = fname)
