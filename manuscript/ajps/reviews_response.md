### Reviewer 1.

*Stronger conceptualization of influence through text reuse required*
	
We should add a more thorough discussion of what text reuse might mean in our context. This also relates to point 3 that the reviewer makes. We could add a more theoretical discussion of different situations from which text reuse might arise (common source, direct influence, chance, formal boiler plate, substantive boiler plate), and discuss effects for our measure

*Does text reuse indicate a continuous or a binary concept (“influence”)*

Maybe add a paragraph discussing this more explicitly. A binary concept still requires a decision for a threshold that maps the continuous score to the binary concept. Discuss that conceptualizing as continuous does not preclude binarizing but should rather be done by researchers using the scores.


*Issues about comparability of text are not addressed*

See 1.

*Arbitrary choice of SW parameters and pre selection parameters*

Easy solution: Refer to the KDD paper where parameters are tuned using the ground truth dataset. Or do separate validation. What objective could we use? One from the validation exercises?

*Expand weighting of alignemnts (discuss approaches other than tf-idf, e.g word2vec)*

Maybe just add a footnote that there are other options to interpret the substantive relevance of a piece of text. This could also be connected to the discussion mentioned in 1. I’m not sure why exactly he brings up word2vec. Embeddigns could be used in a supervised approach to downweight language that is close (in the embedding space) to a set of known boiler plate or irrelevant language. 

*Too little information on the NCSL data as validation dataset, how are bills selected by ncsl, variation between tables, etc.*

For now we randomly sample the tables. We discussed previously that we could hand select tables that are of high quality (high similarity between bills). Reviewer makes a good point that there is a lot of variation between the tables in terms of inclusivity.


*Dynamic implementation section in SW algo description is hard to follow*

Revise (see also Reviewer 2)


*Optimal alignment next to the visualization is confusing*

Easy fix


*Scores in SW figure don’t match scores in text*

Easy fix



### Reviewer 2.

*Language is too jargony and paper is hard to follow for not technical audience*

Revise and more explicitly introduce jargon

*No reference to other political science literature using text as data*

Add in some citations, when introducing the algorighm

*Validation studies ‘do not bring any additional knowledge’ (in terms of substantive political science). Method should be applied to data in other areas*

I don’t think we should follow this advice. The point of a validation study is to assess the quality of a measurement not to generate new substantive insights. 



### Full reviews

Reviewer #2: The paper proposes a modified measurement tool to study similarities between legislative texts in the US politics field (state legislatures), based on text-sequencing algorithms. The authors conduct several validity tests to confirm that ideologically similar bill sponsors reveal a high degree of text reuse, that bills that cover similar policies also reveal text reuse, and that text reuse correlate with the diffusion networks. I think that by and large, an informed reader is able to follow the explanation of the method, the structure is clear - it is a good paper overall.

I do not consider myself a methodologist as such; therefore I will comment from the point of view as a possible user of such a method in other substantive areas. Does the paper do enough scholarly contribution to the discipline to be accepted to the premier journal in political science?

Even though an informed reader familiar with the text analytics will be able to follow the analyses presented, since the submission is t AJPS as opposed to Pol Analysis, I think the authors need to revise it to a considerable degree so that a general political science practitioner interested in applying such methods in his or research will be able to follow. At the very least, the authors need to address and revise frequent methods-related jargon, e.g., "boiler plate removal" encountered in text. I am not sure an average reader of AJPS is familiar with it. I was also surprised that the authors omit several important references to applied text analytics in political science, such as those of Laver, Benoit, Garry 2003, Slapin and Proksch; Lowe; Grimmer, etc (I am not one of these authors and am not related to them, only think it is important to relate to the growing literature on political text so that this paper does not look like a niche paper but as a part of a growing
research program instead).

After reading the paper my overall impression is that it will be very suitable for a special volume on political text, or perhaps for a more specialized journal such as State Politics & Policy Quarterly. As it stands, I think it requires very considerable revisions to be considered for publication in AJPS.

The authors do not introduce any new data - they rely on the existing dataset. They do not offer a new theory that explains the logic behind the re-use of legislative bills, whether based on interest groups literature or the diffusion literature, for example. As such, it is a measurement paper. The SW text re-use algorithm has been previously employed in Political Science in Wilkerson et al (2015), as the authors themselves acknowledge. The authors here re-use the same algorithm, with slight modifications to improve it.  On p. 11 they underline that "In our analyses we use a slightly modified version of the local alignment algorithm, in which the first gap in a series of multiple gaps receives a higher penalty then the following ones (Wilkerson et al., 2015, use the same modification)." "The idea behind this modification is that someone who changes text in a bill might insert several words into an existing piece of text."

Following the estimations of text re-use, the authors report three validation exercises to demonstrate that the texts that they find to be similar based on their analyses are in fact (expected to be) similar, based on other analyses, such as from the ideological distances of bill sponsors. The validation exercises do not bring any additional knowledge since it is expected that ideologically similar bill sponsors will reveal a high degree of text reuse, that bills that cover similar policies will reveal text reuse also. Even though such external validation is important, it does not tell me however, as a possible user of such method, as to the value of the method in my own applied work.

In my humble opinion, the authors can follow two possible avenues. First, if they frame it as mainly a methods paper as they do now, they need to demonstrate the usage of their methods in at least two empirical applications at the back of the paper --- not external validity tests but applications, preferably in different fields and using different text corpora, e.g., one in US politics and another in IR or in European politics. For example, they could take an existing study of policy-making in the US and reveal how their method can be employed by other scholars working in the same area; they can also take the data from the UK parliament or EU parliament and equally apply the text reuse method, to a different corpus however. As it stands, the authors only suggest that the method could be useful, but they do not demonstrate the applications.

The second possibility of course is to reframe the paper altogether by explaining a substantive puzzle in US politics field, using the method to address that puzzle. On p. 26 they suggest several possible applications. The validation analyses can be trimmed or placed into the supplementary materials. Because this paper only improves on the method that is already introduced to the literature, I think the authors could make it into a much more "substantive" piece that still relies on the same method but also explains factors behind the likelihood of text re-use in state legislatures, again possibly utilizing several avenues suggested on p. 26. For example, the paper by Wilkerson et al. 2015 --- that introduced the method to political science --- has a substantive focus on how policy ideas relate to the legislative history of various pieces of legislation, with several examples and illustrations. This paper could be revised along similar lines, with a substantive focus. But I
think the first possibility --- 2 empirical applications to demonstrate the applicability - would require less effort and fewer revisions.



Reviewer #1: As I read it, this manuscript makes three primary contributions. First, the manuscript provides a conceptualization of "policy similarity," and argues that text re-use is related to that conceptual viewpoint. Second, the manuscript provides a description of Smith-Waterman Algorithm (SWAlign), and offers advice and variants on the basic algorithm for potential users. Third, the manuscript provides a series of ground-truth validity tests of the procedure.

Overall, this article makes a noteworthy contribution to the text-as-data literature. Text re-use analyses are becoming increasingly popular throughout political science, and this article advances the state of the literature on these methods. I have some concerns regarding the framing of the article as well as some more specific methodological critiques, but overall I think this is a worthwhile article.

First, in Section 3, I'm convinced that text re-use is an important, politically significant phenomenon, but I'd like a stronger case to be made for the specific conceptual frame used in the paper. Text re-use might indicate policy similarity, or it might indicate a hazier influence relationship of the sort you use in your third section (e.g. through shared drafting norms or databases). The authors should make a stronger case for their preferred conceptualization (e.g. how and why we might know that their particular conceptualization is the right one).

Some further questions on this point:
 - Do we really believe that the measure proposed in this paper is interval-level interpretable? The probability of a long string of text being replicated verbatim or near-verbatim by chance is approximately zero, so we could instead treat similarity scores over a certain threshold as evidence that the authors of a given text were "influenced" by reading a second text. If the latent concept of interest is "policy similarity" (however defined), then presumably we care about more than the simple text on the page. At minimum, we care about implementation, and the relationship between text and implementation is not addressed in this paper. The authors might consider re-framing their notion of policy similarity as "formal similarity," or some similar term.

[Partially Addressed] N


 - If we do want to treat policy similarity as an interval-level concept, do we really believe that we can compare blocks of text directly? Some pieces of text are surely more influential than others, and the authors should at least address the issue of text comparability. The discussion of "boilerplate" text addresses this point implicitly, but problems with comparability of text chunks should be made explicit.

Second, in Sections 4-5, parameter setting decisions throughout the paper are not clearly justified. Is there any reason why we might favor a particular gap/mismatch penalization scheme in SWAlign, or the particular search scheme as articulated the last paragraph in Section 4.2? If parameter setting is essentially arbitrary, are there any opportunities for parameter optimization (e.g. cross-validation against some ground-truth objective), or existing values in the literature?

Third, the discussion of TF-IDF weighting to identify boilerplate text is interesting and novel, and I would like to see it expanded further. Other weighting schemes or boilerplate adjustment mechanisms should be discussed (e.g. using word2vec embeddings to classify boilerplate language). The reason for selecting TF-IDF weights in particular should be described in more detail.

Fourth, I'd like a clearer justification for the choice of the NCSL classification task as a validity exercise. Relatively little detail is given in the paper about methodology that the NCSL used to build their tables and identify comparable documents, the underlying level of variation in the NCSL tables, or similar concerns.

Finally, some smaller notes:
- The discussion of SWAlign is generally good, but the description of the dynamic implementation is somewhat tough to follow.

- In Figure 1, placing the optimal alignment alongside the table is confusing, and suggests that the terms match the axes in the figure.

- Scores inside cells in Figure 1 do not appear to match the parameter values and scores given in text.




