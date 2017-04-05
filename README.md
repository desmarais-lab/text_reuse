## Measuring Policy Similarity through Bill Text Reuse


### Abstract
To evaluate whether text re-use corresponds to the transfer of policy, we test
whether the presence of a diffusion network tie between two states is a
predictor of text reuse. We use the policy diffusion networks inferred in
\citet{desmarais2015}. The diffusion networks were inferred using policy
adoption sequences, and the network inference algorithm developed by
\citet{gomez2010inferring}. A tie from state $i$ to state $j$ in the diffusion
network indicates that state $j$ has frequently emulated state $i$'s policies in
the preceding thirty-five years. To calculate an aggregate alignment score for
each state-pair we calculate the sum of the alignment scores associated with
each pair of bills across the two states. The `Diffusion Ties' variable
indicates the presence of a diffusion edge between states in the 2008 diffusion
network, as measured by \citet{desmarais2015}. The diffusion network in 2008 is
inferred using policy adoptions in the 35 years preceding (and excluding) 2008.
There is one observation in the analysis for each of the 1,225 unique
state-pairs. Since this is dyadic data, we use a matrix permutation method,
quadratic assignment procedure, to calculate $p$-values \citep{krackhardt1988}.
As a robustness check, we run the model with both the identity and log
link.\footnote{The $p$-values were calculated using 5,000 random matrix
permutations.} We also control for a dyadic variable (Coverage) equal to the
product of the number of years for which we have data for each state in the
dyad.


### Replication

See the `makefile` for concrete replication steps. The original data is
currently not publicly available. 
