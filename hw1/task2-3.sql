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
LINES TERMINATED BY '\r\n'
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
LINES TERMINATED BY '\r\n'
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

-- Task 3
DROP TABLE IF EXISTS field_conference;

CREATE TABLE field_conference (
  major VARCHAR(100),
  field VARCHAR(100),
  conference VARCHAR(50)
);

LOAD DATA LOCAL INFILE 'field_conference.csv'
INTO TABLE field_conference
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(major, field, conference);

-- Queries
-- Task 3, A
SELECT
  gai.clean_author_name AS author_name,
  gai.dept AS institution_name,
  SUM(gai.count) AS num_publications
FROM generated_author_info gai
JOIN conference_ranking cr
  ON UPPER(gai.area) = UPPER(cr.acronym)
WHERE cr.conf_rank = 'A*'
  AND gai.year BETWEEN 2010 AND 2024
GROUP BY gai.clean_author_name, gai.dept
ORDER BY
  num_publications DESC,
  author_name ASC,
  institution_name ASC
LIMIT 100;

-- Task 3, B
WITH astar AS (
  SELECT UPPER(acronym) AS conf
  FROM conference_ranking
  WHERE conf_rank = 'A*'
),
inst_field AS (
  SELECT
    fc.field,
    gai.dept AS institution,
    SUM(gai.count) AS num_publications
  FROM generated_author_info gai
  JOIN astar a
    ON UPPER(gai.area) = a.conf
  JOIN field_conference fc
    ON UPPER(fc.conference) = UPPER(gai.area)
  WHERE gai.year BETWEEN 2010 AND 2024
  GROUP BY fc.field, gai.dept
),
ranked AS (
  SELECT *,
         DENSE_RANK() OVER (
           PARTITION BY field
           ORDER BY num_publications DESC
         ) AS rnk
  FROM inst_field
)
SELECT field, institution, num_publications
FROM ranked
WHERE rnk <= 10
ORDER BY field, num_publications DESC, institution;

-- Task 3, C
WITH astar AS (
  SELECT UPPER(acronym) AS conf
  FROM conference_ranking
  WHERE conf_rank = 'A*'
),
inst_counts AS (
  SELECT
    gai.dept AS institution,
    SUM(gai.count) AS num_publications
  FROM generated_author_info gai
  JOIN astar a
    ON UPPER(gai.area) = a.conf
  WHERE gai.year BETWEEN 2010 AND 2024
  GROUP BY gai.dept
),
ranked AS (
  SELECT *,
         DENSE_RANK() OVER (ORDER BY num_publications DESC) AS rnk
  FROM inst_counts
)
SELECT institution, num_publications
FROM ranked
WHERE rnk <= 25
ORDER BY num_publications DESC, institution;

-- Task 3, D
DROP TABLE IF EXISTS data;

CREATE TABLE data (
  `institution.displayName` VARCHAR(255),
  `institution.schoolType` VARCHAR(100),
  `institution.aliasNames` TEXT,
  `institution.state` VARCHAR(10),
  `institution.city` VARCHAR(100),
  `institution.zip` VARCHAR(20),
  `institution.region` VARCHAR(50),
  `institution.isPublic` VARCHAR(20),
  `institution.institutionalControl` VARCHAR(50),
  `institution.primaryPhotoCardThumb` TEXT,
  `ranking.displayRank` VARCHAR(50),
  `ranking.sortRank` INT,
  `ranking.isTied` VARCHAR(20),
  `searchData.actAvg.rawValue` VARCHAR(50),
  `searchData.percentReceivingAid.rawValue` VARCHAR(50),
  `searchData.acceptanceRate.rawValue` VARCHAR(50),
  `searchData.tuition.rawValue` VARCHAR(50),
  `searchData.hsGpaAvg.rawValue` VARCHAR(50),
  `searchData.engineeringRepScore.rawValue` VARCHAR(50),
  `searchData.parentRank.rawValue` VARCHAR(50),
  `searchData.enrollment.rawValue` VARCHAR(50),
  `searchData.businessRepScore.rawValue` VARCHAR(50),
  `searchData.satAvg.rawValue` VARCHAR(50),
  `searchData.costAfterAid.rawValue` VARCHAR(50),
  `searchData.testAvgs.displayValue.0.value` VARCHAR(50),
  `searchData.testAvgs.displayValue.1.value` VARCHAR(50)
);

LOAD DATA LOCAL INFILE 'data.csv'
INTO TABLE data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Query
WITH inst_counts AS (
  SELECT
    gai.dept AS institution,
    SUM(gai.count) AS pubs
  FROM generated_author_info gai
  JOIN conference_ranking cr
    ON UPPER(gai.area) = UPPER(cr.acronym)
  WHERE cr.conf_rank = 'A*'
    AND gai.year BETWEEN 2010 AND 2024
  GROUP BY gai.dept
),
our_rank AS (
  SELECT
    institution,
    DENSE_RANK() OVER (ORDER BY pubs DESC, institution ASC) AS our_rank
  FROM inst_counts
),
our_top25 AS (
  SELECT institution, our_rank
  FROM our_rank
  WHERE our_rank <= 25
),
us_top25 AS (
  SELECT
    `institution.displayName` AS institution,
    `ranking.sortRank` AS us_rank
  FROM data
  WHERE `ranking.sortRank` IS NOT NULL
    AND `ranking.sortRank` > 0
  ORDER BY `ranking.sortRank`
  LIMIT 25
),
all_unis AS (
  SELECT institution FROM our_top25
  UNION
  SELECT institution FROM us_top25
),
paired AS (
  SELECT
    u.institution,
    COALESCE(o.our_rank, 26) AS our_rank,
    COALESCE(us.us_rank, 26) AS us_rank,
    (COALESCE(o.our_rank, 26) - COALESCE(us.us_rank, 26)) AS d
  FROM all_unis u
  LEFT JOIN our_top25 o ON o.institution = u.institution
  LEFT JOIN us_top25 us ON us.institution = u.institution
)
SELECT
  COUNT(*) AS n,
  SUM(d*d) AS sum_d2,
  ROUND(
    1 - (6 * SUM(d*d)) / (COUNT(*) * (COUNT(*) * COUNT(*) - 1)),
    5
  ) AS spearman_rho
FROM paired;

-- Task 3, E
SELECT
  `institution.state` AS state,
  `institution.institutionalControl` AS institutional_control,
  AVG(CAST(NULLIF(REPLACE(`searchData.tuition.rawValue`, ',', ''), '') AS DECIMAL(12,2))) AS avg_tuition,
  AVG(CAST(NULLIF(`searchData.acceptanceRate.rawValue`, '') AS DECIMAL(12,6))) AS avg_acceptance_rate,
  AVG(CAST(NULLIF(REPLACE(`searchData.enrollment.rawValue`, ',', ''), '') AS DECIMAL(12,2))) AS avg_enrollment
FROM data
GROUP BY `institution.state`, `institution.institutionalControl` WITH ROLLUP;

