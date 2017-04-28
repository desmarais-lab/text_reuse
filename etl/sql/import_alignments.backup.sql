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
ALTER TABLE temp1 ADD id text;
UPDATE temp1 SET id = left_id || '_' || right_id;
ALTER TABLE temp1 ADD PRIMARY KEY (id);

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
ALTER TABLE temp ADD id text;
UPDATE temp SET id = left_id || '_' || right_id;
ALTER TABLE temp ADD PRIMARY KEY (id);

-- Create the final table
SELECT temp1.*, temp.adjusted_alignment_score
INTO alignments
FROM temp1
JOIN temp
    ON temp1.id = temp.id;
DROP TABLE temp;
DROP TABLE temp1;
