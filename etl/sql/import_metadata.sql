DROP TABLE bill_metadata;
CREATE TABLE bill_metadata (
    unique_id text primary key,
    date_introduced date,
    date_signed date,
    state text,
    chamber text,
    bill_length integer,
    num_sponsors integer,
    short_title text,
    year_introduced integer,
    year_signed integer,
    sponsor_ideology real
);
\COPY bill_metadata FROM 'metadata.csv' DELIMITER ',' CSV HEADER NULL as 'NA';
