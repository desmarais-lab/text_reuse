library(dplyr)
library(ggplot2)

# Load Alignments
cat("Loading alignment data...\n")
fast_read <- function(filename) {
    samp <- read.table(filename, header = TRUE, nrows = 2, 
                       stringsAsFactors = FALSE, sep = ',')
    classes <- sapply(samp, class)
    return(read.table(filename, header = TRUE, colClasses = classes,
                      stringsAsFactors = FALSE, sep = ',', 
                      comment.char = ""))
}

alignments <- tbl_df(fast_read('../../data/aligner_output/alignments_notext.csv'))

# Remove 0 alignments
# Choose weighted score as alignmetn score (weighted score from sample 1)
alignments <- filter(alignments, adjusted_alignment_score > 0)

# Load metadata
cat("Loading and cleaning metadata...\n")
meta <- tbl_df(read.csv('../../data/bill_metadata.csv', 
                        stringsAsFactors = FALSE, header = TRUE, 
                        quote = '"')) %>%
    select(-session) %>%
    mutate(sponsor_ideology = as.numeric(sponsor_idology),
           num_sponsors = as.integer(num_sponsors),
           bill_length = as.integer(bill_length))

### Make 'None' NA
meta[meta == 'None'] <- NA
meta[meta == ''] <- NA

## Match alignments with ideology scores
### Join info on left bill
cat("Joining datasets...\n")
temp <- mutate(meta, left_id = unique_id, left_ideology = sponsor_idology,
               left_length = bill_length) %>%
    dplyr::select(left_id, left_ideology, left_length)
df <- left_join(alignments, temp, by = c("left_id"))

### Join info on right bill
temp <- mutate(meta, right_id = unique_id, right_ideology = sponsor_idology,
               right_length = bill_length) %>%
    dplyr::select(right_id, right_ideology, right_length)
df <- left_join(df, temp, by = "right_id")

# Calculate ideological distance
df <- mutate(df, ideology_dist = (left_ideology - right_ideology)^2)

cat("Descriptives for ideology data\n")

# Stats for text
sink('data_desc_stats.txt')
n <- nrow(df)
cat(paste0("Preprocessed data from ", n, " bill dyads.\n"))
df <- filter(df, !is.na(ideology_dist))
m <- nrow(df)
cat(paste0((1 - m / n) * 100, "% of dyads missing ideological distance.\n"))
cat(paste0((n - m), " bills don't have ideological distance \n"))
cat(paste0(m, " valid dyads from ", length(unique(df$left_id)), 
           " left bills and ", length(unique(df$right_id)), 
           " right bills remaining.\n"))
sink()

# Save ideology data
fname <- "../../data/ideology_analysis_input.RData"
df <- select(df, adjusted_alignment_score, ideology_dist, left_id)
cat(paste0("Saving to ", fname, "\n"))
save(df, file = fname)
