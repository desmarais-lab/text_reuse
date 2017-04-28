-- First import alignments and text
CREATE TABLE temp1 (
    left_id text,
    right_id text,
    score double precision,
    left_alignment_text text,
    right_alignment_text text,
    lucene_score double precision,
    max_lucene_score double precision,
    compute_time double precision 
);
\COPY temp1 FROM '../../data/aligner_output/alignments.csv' DELIMITER ',' CSV HEADER NULL as '';

-- Now add the adjusted scores
CREATE TABLE temp (
    left_id text,
    right_id text,
    score double precision,
    lucene_score double precision,
    max_lucene_score double precision,
    adjusted_alignment_score double precision 
);
\COPY temp FROM '../../data/aligner_output/alignments_notext.csv' DELIMITER ',' CSV HEADER NULL as '';

-- Create the final table
SELECT temp1.*, temp.adjusted_alignment_score
INTO alignments
FROM temp1
JOIN temp
    ON temp1.left_id = temp.left_id
    AND temp1.right_id = temp.right_id;
DROP TABLE temp;
DROP TABLE temp1;

CREATE INDEX id ON alignments (left_id, right_id);
CREATE INDEX score_idx ON alignments (score);
CREATE INDEX adj_score_idx ON alignments (adjusted_alignment_score);
