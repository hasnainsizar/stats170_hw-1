-- schema
USE stats170;

DROP TABLE IF EXISTS csv_data;

CREATE TABLE csv_data (
    id INT,
    name VARCHAR(100),
    age INT,
    city VARCHAR(100),
    signup_date DATE,
    purchases INT,
    active BOOLEAN
);

-- Loading csv
LOAD DATA LOCAL INFILE '/Users/hasnainsizar/Desktop/stats170/data.csv'
INTO TABLE csv_data
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, name, age, city, signup_date, purchases, @active)
SET active = (UPPER(@active) = 'TRUE');

#Queries
-- Q1
SELECT * FROM csv_data LIMIT 10;
-- Q2
SELECT DISTINCT city FROM csv_data;
-- Q3
SELECT city, AVG(age) FROM csv_data GROUP BY city;
-- Q4
SELECT name, purchases FROM csv_data ORDER BY purchases DESC;
