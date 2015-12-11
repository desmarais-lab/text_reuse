# Quadratic Assignment Procedure for Sparse Networks

# Arguments:

# bill_similarity: data.frame, left_id (chr), right_id(chr), score(dbl)
# ideology: dataframe, mapping bill_id (chr) to ideology (dbl)
# nperm: number of quap iterations
# cores: number of cores for parallelization of nperm loop

qap <- function(edges, ideologies, nperm = 100, cores = 1) {
    
    require(doParallel) 
   
    # All integer node ids
    all <- unique(c(edges[, 1], edges[, 2])) 
    
    # Function that does one iteration of the qap algorithm 
    qap_iter <- function() {
        
        # Randomize mapping node_id -> permuted_node_id 
        mapping <- sample(all) 
         
        # Calculate distance vector for permuted dyads
        dists <- (ideologies[mapping[edges[, 1]]] - ideologies[mapping[edges[, 2]]])^2
      
        # Fit the model
        coef <- lm(log(edges[, 3]) ~ dists)$coef[2]
        return(coef)
    }
    
    # Make cluster for parallel processing
    cat("Generating psock cluster...\n")
    cl <- makeCluster(cores)
    registerDoParallel(cl)
    
    # nperm loop (parallel) 
    cat("Running qap...\n")
    coefs <- foreach(i = c(1:nperm), .combine = c) %dopar% qap_iter() 
   
    stopCluster(cl) 
    return(coefs) 
}
