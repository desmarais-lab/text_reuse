library(dplyr)
library(sna)
library(network)

# Load data
df <- tbl_df(read.csv('alignment_scores_only.csv', header = TRUE, 
                      stringsAsFactors = FALSE)
             )

# Extract some additional info
ret_first <- function(x) return(x[1])
df <- mutate(df, edge_id = paste0(left_doc_id, '_', right_doc_id),
             alignmen_score = as.numeric(alignment_score),
             left_state = sapply(strsplit(df$left_doc_id, '_'), ret_first),
             right_state = sapply(strsplit(df$right_doc_id, '_'), ret_first))
        
# Aggregate the bills
df_bills <- group_by(df, edge_id) %>% 
    summarize(num_alignments = n(),
    sum_score = sum(alignment_score),
    states_id = paste0(left_state[1], right_state[1]),
    left_state = left_state[1],
    right_state = right_state[1])
    
n_nodes <- length(unique(c(df$left_doc_id, df$right_doc_id)))

# Aggregate states
df_states <- group_by(df_bills, states_id) %>%
    summarize(alignments = sum(num_alignments),
              total_alignment_score = sum(sum_score),
              left_state = left_state[1],
              right_state = right_state[1])

# Store the aggregated dfs
write.csv(df_bills, file = 'bill_network.csv', row.names = FALSE)
write.csv(df_states, file = 'states_network.csv', row.names = FALSE)

# Visualize the states network
states <- network(df_states[, c("left_state", "right_state", "alignments")], 
                  matrix.type = "edgelist")

