require(quantreg)
# Quadratic Assignment Procedure for Sparse Networks

# Arguments:

# edges: Edgelist for similarity network. Bill IDs must be integers 
# ideology: numeric vector of bill ideologies. Must be in same order as integer
#   bill ids
# nperm: number of quap iterations
# cores: number of cores for parallelization of nperm loop

qap <- function(edges, ideologies, nperm = 100, cores = 1, mode = "linear",
                tau = NULL) {
    
    require(doParallel) 
    
    
    if(mode == "quantile" & is.null(tau)) stop("No quantile for rq specified.")
     
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
        if(mode == "linear") {
            coef <- lm(log(edges[, 3]) ~ dists)$coef[2]
        } else if(mode == "quantile") {
            coef <- rq(log(edges[, 3]) ~ dists)$coef[2]
        } else {
            stop("Invalid mode argument")
        }
        return(coef)
    }
    
    # Make cluster for parallel processing
    cat("Generating psock cluster...\n")
    cl <- makeCluster(cores)
    registerDoParallel(cl)
    
    # nperm loop (parallel) 
    cat("Running qap...\n")
    coefs <- foreach(i = c(1:nperm), .combine = c, .packages = 'quantreg') %dopar% {
        qap_iter() 
    }
   
    stopCluster(cl) 
    return(coefs) 
}
