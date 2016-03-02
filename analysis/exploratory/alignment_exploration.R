library(dplyr)
library(xtable)

# Bill to bill alignment scores
btb <- tbl_df(read.csv('../../data/lid/aggregate_btb_alignments.csv', 
                      stringsAsFactors = FALSE, fileEncoding = 'utf-8')) %>%
    arrange(-sum_score_length)

# Bill metadata
ret_last <- function(x) return(x[length(x)])
ret_first <- function(x) return(x[1])
meta <- tbl_df(read.csv('../../data/bill_metadata.csv', 
                        stringsAsFactors = FALSE)) %>% 
    mutate(state_id = sapply(strsplit(unique_id, '_'), ret_last),
           year = as.integer(sapply(strsplit(date_introduced, '-'), ret_first)))

filter(meta, (state == "nj" & state_id == "S2360"))

filter(meta, (state == 'az' & state_id == "SB1070" & year == 2011)) %>%
    select(unique_id, bill_title)


# Example Tables

other_bill <- function(x, y, name) ifelse(x != name, x, y)

## Recycling act
mo_2013_SB363 <- as.data.frame(filter(btb, (left_doc_id == "mo_2013_SB363" | 
                                        right_doc_id == "mo_2013_SB363"))) %>% 
    arrange(left_doc_id, sum_score) %>%
    mutate(matched_bill = other_bill(left_doc_id, right_doc_id, "mo_2013_SB363")) %>%
    dplyr::select(matched_bill, sum_score, ideology_dist, 
                  left_length, right_length)


## Balanced Budget act
nc_2015_HB366 <- as.data.frame(filter(btb, (left_doc_id == "nc_2015_HB366" | 
                                        right_doc_id == "nc_2015_HB366"))) %>% 
    arrange(left_doc_id, sum_score) %>%
    mutate(matched_bill = other_bill(left_doc_id, right_doc_id, "nc_2015_HB366")) %>%
    dplyr::select(matched_bill, sum_score, ideology_dist, 
                  left_length, right_length)
