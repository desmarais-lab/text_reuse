DROP TABLE alignment_lengths;
SELECT ARRAY_length(REGEXP_SPLIT_TO_ARRAY(left_alignment_text, '\s+'), 1) 
        AS left_alignment_length, 
    ARRAY_length(REGEXP_SPLIT_TO_ARRAY(right_alignment_text, '\s+'), 1) 
        AS right_alignment_length,
    left_id AS left_id,
    right_id AS right_id
INTO alignment_lengths
FROM alignments;
