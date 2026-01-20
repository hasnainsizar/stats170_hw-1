USE stats170;
DROP TABLE IF EXISTS conference_ranking;

-- Task 2, A
CREATE TABLE conference_ranking (
  acronym VARCHAR(50),
  name VARCHAR(512),
  conf_rank VARCHAR(5),
  academic_society VARCHAR(20)
);

LOAD DATA LOCAL INFILE 'conference_ranking.csv'
INTO TABLE conference_ranking
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(acronym, name, conf_rank);

UPDATE conference_ranking
SET academic_society =
  CASE
    WHEN name LIKE '%ACM%' AND name LIKE '%IEEE%' THEN 'ACM+IEEE'
    WHEN name LIKE '%ACM%' THEN 'ACM'
    WHEN name LIKE '%IEEE%' THEN 'IEEE'
    ELSE 'other'
  END;

SELECT COUNT(*) AS conference_ranking_rows FROM conference_ranking;
SELECT * FROM conference_ranking LIMIT 5;

-- Task 2, B
-- csrankings.csv
DROP TABLE IF EXISTS csrankings;

CREATE TABLE csrankings (
  author_name VARCHAR(255),
  affiliation VARCHAR(255),
  homepage VARCHAR(512),
  scholarid VARCHAR(128),
  first_name VARCHAR(100),
  middle_name VARCHAR(100),
  last_name VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'csrankings.csv'
INTO TABLE csrankings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(author_name, affiliation, homepage, scholarid);

UPDATE csrankings
SET first_name = SUBSTRING_INDEX(author_name, ' ', 1),
    last_name  = SUBSTRING_INDEX(author_name, ' ', -1),
    middle_name =
      NULLIF(
        TRIM(
          REPLACE(
            REPLACE(author_name, SUBSTRING_INDEX(author_name, ' ', 1), ''),
            SUBSTRING_INDEX(author_name, ' ', -1),
            ''
          )
        ),
        ''
      );

-- Queries
SELECT COUNT(*) AS csrankings_rows FROM csrankings;
SELECT * FROM csrankings LIMIT 5;

-- generated-author-info.csv
DROP TABLE IF EXISTS generated_author_info;

CREATE TABLE generated_author_info (
  author_name VARCHAR(255),
  dept VARCHAR(255),
  area VARCHAR(50),
  count INT,
  adjustedcount DECIMAL(10,4),
  year INT,
  first_name VARCHAR(100),
  middle_name VARCHAR(100),
  last_name VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'generated-author-info.csv'
INTO TABLE generated_author_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(author_name, dept, area, count, adjustedcount, year);

UPDATE generated_author_info
SET first_name = SUBSTRING_INDEX(author_name, ' ', 1),
    last_name  = SUBSTRING_INDEX(author_name, ' ', -1),
    middle_name =
      NULLIF(
        TRIM(
          REPLACE(
            REPLACE(author_name, SUBSTRING_INDEX(author_name, ' ', 1), ''),
            SUBSTRING_INDEX(author_name, ' ', -1),
            ''
          )
        ),
        ''
      );

-- Queries
SELECT COUNT(*) AS generated_author_info_rows FROM generated_author_info;
SELECT * FROM generated_author_info LIMIT 5;


-- Task 2, C
SELECT COUNT(*) AS csrankings_suffix_count
FROM csrankings
WHERE author_name REGEXP ' [0-9]+$';

SELECT COUNT(*) AS generated_author_info_suffix_count
FROM generated_author_info
WHERE author_name REGEXP ' [0-9]+$';

ALTER TABLE csrankings
ADD COLUMN clean_author_name VARCHAR(255);

ALTER TABLE generated_author_info
ADD COLUMN clean_author_name VARCHAR(255);

-- Populate 
UPDATE csrankings
SET clean_author_name = REGEXP_REPLACE(author_name, ' [0-9]+$', '');

UPDATE generated_author_info
SET clean_author_name = REGEXP_REPLACE(author_name, ' [0-9]+$', '');

-- Validation Counts 
SELECT COUNT(*)
FROM csrankings
WHERE clean_author_name REGEXP ' [0-9]+$';

SELECT COUNT(*)
FROM generated_author_info
WHERE clean_author_name REGEXP ' [0-9]+$';