## Alignments

### alignments.csv

This contains the alignments including the aligned text in csv format. The decompressed filesize is about 37GB. Due to the dataverse file size limitations, the file is compressed with gzip and chunked into approximately 2.5GB (compressed) chunks. To re-constitute the decompressed csv file download all files with the suffix `alignments.csv.gz_`. Then run the following command from the directory where the files are stored:

```
cat alignments.csv.gz_* | zcat > alignments.csv
```

The resulting csv file contains the following columns:

* `left_id`: Id of the left bill.
* `right_id`: Id of the right bill.
* `score`: Raw alignment score.
* `left_alignment_text`: Aligned text from the left bill. Gaps are indicated by a `-`.
* `right_alignment_text`: Aligned text from the right bill. Gaps are indicated by a `-`.
* `lucene_score`: The similarity score as calculated by the Elastic Search `more-like-this-query` for the bill pair. Note that this score is only meaningful relative to the `max_lucene_score`. (See the lucene search engine documentation for details).
* `max_lucene_score`: The maximum similarity score that occured for the left bill (`left_id`).
* `compute_time`: Time (seconds) required to compute this alignment.

### alignments_notext.csv

This file contains all alignments excluding the alignment text. The file is compressed with gzip. The decompressed filesize is approximately 14GB. It additionally contains the scores that are adjusted for boiler plate text (see the paper for details on the boiler plate adjustment procedure).

Columns:

* `left_id`: Id of the left bill.
* `right_id`: Id of the right bill.
* `score`: Raw alignment score.
* `lucene_score`: The similarity score as calculated by the Elastic Search `more-like-this-query` for the bill pair. Note that this score is only meaningful relative to the `max_lucene_score`. (See the lucene search engine documentation for details).
* `max_lucene_score`: The maximum similarity score that occured for the left bill (`left_id`).
* `adjuste_alignment_score`: Raw score weighted by the inverse of the frequency of the alignment text.


## Bill text

The original bill text and metadata can be found in `state_bills_json.gz`. The file is compressed with `gzip`, the size of the uncompressed file is about 15GB.

When using this data please acknowledge [openstates.org](openstates.org) and
cite this paper: 

Burgess, Matthew, Eugenia Giraudy, Julian Katz-Samuels, Joe Walsh, Derek Willis, Lauren Haynes, and Rayid Ghani. "The Legislative Influence Detector: Finding Text Reuse in State Legislation." In Proceedings of the 22nd ACM SIGKDD International Conference on Knowledge Discovery and Data Mining, pp. 57-66. ACM, 2016.

Data is stored in `json` format, one `json` formatted bill per line. Each bill has the following fields:

* `date_signed`: When the bill was signed into law. `null` if not signed.
* `date_introduced`: Date when the bill was introduced in the legislature.
* `bill_document_first`: Full text of the bill at introduction.
* `date_updated`
* `short_title`
* `bill_type`
* `actions`: Array of legislative actions on the bill
* `summary`
* `chamber`
* `state`
* `session`
* `action_dates`: Array of major legislative actions (passing, signing)
* `unique_id`
* `bill_document_last`: Last available version of the bill text.
* `date_created`
* `bill_title`
* `sponsers`: Legislators who officially sponsored this bill
* `bill_id`: Legislature's id (not necessarily unique)
* `sunlight_id`: Sunlight foundation id
