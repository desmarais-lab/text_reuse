library(dplyr)

ncsl_bills <- tbl_df(read.csv('../../data/ncsl/ncsl_data_from_sample.csv', 
                       header = TRUE, stringsAsFactors = FALSE))
# Check for duplicates
ncsl_bills <- mutate(ncsl_bills, unique_id = paste0(id, '_', state, '_', year)) %>%
    select(-table, -description)
ncsl_bills <- ncsl_bills[!duplicated(ncsl_bills$unique_id),]

db_bills <- tbl_df(read.csv('../../data/bill_metadata.csv', header = TRUE,
                     stringsAsFactors = FALSE))

# Preprocess db bills

## Extract id from unique id
db_bills$id <- unlist(lapply(strsplit(db_bills$unique_id, '_'), 
                             function(x) x[length(x)]))

## Split into numeric and letter components
db_bills$num_id <- as.integer(gsub('[[:alpha:]]', '', db_bills$id))
db_bills$let_id <- gsub('[[:digit:]]', '', db_bills$id)

## Extract year of introduction
db_bills$year <- as.integer(sapply(strsplit(db_bills$date_introduced, '-'), 
                                   function(x) x[1]))

# Preprocess ncsl ids
## Split into components
ncsl_bills$num_id <- as.integer(gsub('[[:alpha:]]', '', ncsl_bills$id))
ncsl_bills$let_id <- gsub('[[:digit:]]', '', ncsl_bills$id)


# Matching
db_bills <- tbl_df(db_bills) %>% select(state, year, id, num_id, let_id, unique_id)
no_match <- 0
multi_match <- 0
one_match <- 0
ncsl_bills$matched_from_db <- NA

for(i in 1:nrow(ncsl_bills)) {
    id_ <- ncsl_bills$id[i]
    num_ <- ncsl_bills$num_id[i]
    let_ <- ncsl_bills$let_id[i]
    state_ <- tolower(ncsl_bills$state[i])
    year_ <- ncsl_bills$year[i]
    
    # Get relevant subset
    subs <- filter(db_bills, state == state_, year == year_, num_id == num_)
    if(nrow(subs) == 0) {
        print(paste('(LVL1)No match for:', state_, id_, year_))
        no_match <- no_match + 1
        next
    } else {
        if(nrow(subs) == 1) {
            print(paste('(LVL2)Found match for:', state_, id_, year_))
            one_match <- one_match + 1
            ncsl_bills$matched_from_db[i] <- subs$unique_id
        } else {
            # Match multiple
            subs_ <- filter(subs, let_id == let_)
            if(nrow(subs_) == 1) {
                print(paste('(LVL3)Found match for:', state_, id_, year_))
                one_match <- one_match + 1
                ncsl_bills$matched_from_db[i] <- subs_$unique_id
            } else {
                if(nrow(subs_) == 0) {
                    # Distance matching procedure
                    subs$first <- sapply(strsplit(subs$let_id, ''), 
                                         function(x) x[1])
                    let_first_ <- unlist(strsplit(let_, ''))[1]
                    subs <- filter(subs, first == let_first_)
                    if(nrow(subs) == 1) {
                        print(paste('(LVL4)Found match for:', state_, id_, 
                                    year_))
                        one_match <- one_match + 1
                        ncsl_bills$matched_from_db[i] <- subs$unique_id
                    } else {
                        if(nrow(subs) == 0){
                            print(paste('(LVL4)No match for:', state_, id_, 
                                        year_))
                            no_match <- no_match + 1
                        } else {
                            print(paste('(LVL4)Multiple matches on num and let for:', 
                                  state_, id_, year_))
                            print(subs)
                            multi_match <- multi_match + 1
                        }
                    }
                } else {
                    print(paste('(LVL3)Multiple matches on num and let for:', state_, 
                          id_, year_))
                    print(subs_)
                    multi_match <- multi_match + 1
                }
            }
        }
        
    }
    
}

print(paste('Found', one_match, 'matches'))
print(paste(no_match, 'not matched'))
print(paste(multi_match, 'multiple matches'))

out <- select(ncsl_bills, matched_from_db) %>%
    filter(!is.na(matched_from_db))
write.table(out, file = '../../data/ncsl/matched_ncsl_bill_ids.txt', 
          row.names = FALSE, quote = FALSE, sep = ",", col.names = FALSE)
write.table(ncsl_bills, 
            file = '../../data/ncsl/ncsl_data_from_sample_matched.csv', 
            row.names = FALSE, quote = FALSE, sep = ",")
