library(dplyr)
library(ggplot2)
library(stargazer)

# Load Alignments
cat("Loading alignment data...\n")
fast_read <- function(filename) {
    samp <- read.table(filename, header = TRUE, nrows = 2, 
                       stringsAsFactors = FALSE, sep = ',')
    classes <- sapply(samp, class)
    return(read.table(filename, header = TRUE, colClasses = classes,
                      stringsAsFactors = FALSE, sep = ',', 
                      comment.char = "", nrows = 1000))
}


alignments <- tbl_df(fast_read('../../data/aligner_output/alignments_notext.csv'))

# Remove 0 alignments
# Choose weighted score as alignmetn score (weighted score from sample 1)
alignments <- filter(alignments, adjusted_alignment_score > 0)

# Load metadata
cat("Loading and cleaning metadata...\n")
meta <- read.csv('../../data/bill_metadata.csv', stringsAsFactors = FALSE,
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


## Match alignments with ideology scores
### Join info on left bill
cat("Joining datasets...\n")
temp <- mutate(meta, left_id = unique_id, left_ideology = sponsor_idology,
               left_length = bill_length) %>%
    dplyr::select(left_doc_id, left_ideology, left_length)
df <- left_join(alignments, temp, by = "left_id")

### Join info on right bill
temp <- mutate(meta, right_id = unique_id, right_ideology = sponsor_idology,
               right_length = bill_length) %>%
    dplyr::select(right_doc_id, right_ideology, right_length)
df <- left_join(df, temp, by = "right_id")

# Calculate ideological distance
df <- mutate(df, ideology_dist = (left_ideology - right_ideology)^2)

cat("Descriptives for ideology data\n")
cat("***********************************************************************\n")

# Stats for text
sink('data_desc_stats.txt')
n <- nrow(df)
cat(paste0("Preprocessed data from ", n, " bill dyads.\n"))
df <- filter(df, !is.na(ideology_dist))
m <- nrow(df)
cat(paste0((1 - m / n), "% of dyads missing ideological distance.\n"))
cat(paste0((n - m), " bills don't have ideological distance \n"))
cat(paste0(m, " valid dyads from ", length(unique(df$left_doc_id)), 
           " left bills and ", length(unique(df$right_doc_id)), 
           " right bills remaining.\n"))
sink()

# Save ideology data
fname <- "../../data/ideology_analysis_input.RData"

cat(paste0("Saving to ", fname, "\n"))
save(df, file = fname)
