-- to see data dir within pgadmin
SHOW data_directory;

-------------------------------------------------------------------------
-- Ex 1. Create mta_no_index table using NY_MTA.csv without any index.
-- How long does it take to insert data?
-------------------------------------------------------------------------
DROP TABLE IF EXISTS mta_no_index;

CREATE TABLE mta_no_index (plaza_id INTEGER,
						   date DATE,
						   hr INTEGER,
						   direction VARCHAR(1),
						   vehicles_ez INTEGER, 
						   vehicles_cash INTEGER)

COPY mta_no_index FROM '/data/NY_MTA.csv' CSV HEADER; -- 2.63 sec
SELECT * FROM mta_no_index -- 0.897 sec

-- Hash functions
SELECT HASH_NUMERIC(100) --1186574835
SELECT HASHTEXT('sample') --1573005290

-------------------------------------------------------------------------
--EX 2 Create mta_hash table using NY_MTA.csv with plaza_id hash-indexed.
--How long does it take to insert data?
-------------------------------------------------------------------------

DROP TABLE IF EXISTS mta_hash;

CREATE TABLE mta_hash (plaza_id INTEGER,
					   date DATE, 
					   hr INTEGER, 
					   direction VARCHAR(1), 
					   vehicles_ez INTEGER, 
					   vehicles_cash INTEGER);
					   
CREATE INDEX plaza_id_hash ON mta_hash USING hash(plaza_id);

COPY mta_hash FROM '/data/NY_MTA.csv' CSV HEADER; -- 44.62 sec, takes longer due to sorting data

-------------------------------------------------------------------------
--- EX 3 Create mta_btree table using NY_MTA.csv with plaza_id b-tree indexed.
-- How long does it take to insert data?
-- Make sure to cluster the table using plaza_id.
-------------------------------------------------------------------------

DROP TABLE IF EXISTS mta_btree;

CREATE TABLE mta_btree (plaza_id INTEGER,
					   date DATE, 
					   hr INTEGER, 
					   direction VARCHAR(1), 
					   vehicles_ez INTEGER, 
					   vehicles_cash INTEGER);
					   
CREATE INDEX plaza_id_btree ON mta_btree USING btree(plaza_id);

COPY mta_btree FROM '/data/NY_MTA.csv' CSV HEADER; -- 3.98 sec

CLUSTER mta_btree USING plaza_id_btree; -- 2.98 sec

-------------------------------------------------------------------------
--EX 4 Analyze the following in the mta_no_index table.
--Scan
--Equality Selection - plaza_id is 1
--Range Selection - plaza_id is great than 10
--Insert  - (101, '2020-09-22', 23, 'I', 415, 422)
--Delete - the inserted row
-------------------------------------------------------------------------

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_no_index; 
-- 185 ms exec, 0.078 ms plan

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_no_index WHERE plaza_id = 1;
-- 149 ms exec, 0.059 ms plan

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_no_index WHERE plaza_id > 10;
-- 204 ms exec, 0.060 ms plan

EXPLAIN ANALYZE VERBOSE INSERT INTO mta_no_index VALUES (101, '2020-09-22', 23, 'I', 415, 422) 
-- 0.057 ms exec, 0.030 ms plan

EXPLAIN ANALYZE VERBOSE DELETE FROM mta_no_index WHERE plaza_id = 101 AND 
														date = '2020-09-22' AND
														direction = 'I' AND
														vehicles_ez = 415 AND
														vehicles_cash = 422; 
-- 165 ms exec, 0.066 ms plan

-- tldr: insert is fast because it is just writing data to the last page

-------------------------------------------------------------------------
--EX 5 Analyze the following in the mta_hash table.
--Scan
--Equality Selection - plaza_id is 1
--Range Selection - plaza_id is great than 10
--Insert  - (101, '2020-09-22', 23, 'I', 415, 422)
--Delete - the inserted row
-------------------------------------------------------------------------

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_hash; 
-- 188 ms exec, 0.197 ms plan

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_hash WHERE plaza_id = 1; 
-- 0.144 ms exec, 0.000091 ms plan

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_hash WHERE plaza_id > 10;
-- 160 ms exec, 0.104 ms plan

EXPLAIN ANALYZE VERBOSE INSERT INTO mta_hash VALUES (101, '2020-09-22', 23, 'I', 415, 422) 
-- 1.252 ms exec, 0.037 ms plan

EXPLAIN ANALYZE VERBOSE DELETE FROM mta_hash WHERE plaza_id = 101 AND 
														date = '2020-09-22' AND
														direction = 'I' AND
														vehicles_ez = 415 AND
														vehicles_cash = 422;
-- 0.054 ms exec, 0.075 ms plan

-- equality search is faster than no index, so is deletion
-- scan is a bit slower than no index
-- hash doesnt know range so range selection is not much faster than no index
-- inserting requires applying hash function, so slower than no index

-------------------------------------------------------------------------
--EX 6 Analyze the following in the mta_btree table.
--Scan
--Equality Selection - plaza_id is 1
--Range Selection - plaza_id is great than 10
--Insert  - (101, '2020-09-22', 23, 'I', 415, 422)
--Delete - the inserted row
-------------------------------------------------------------------------

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_btree; 
-- 188 ms exec, 0.197 ms plan

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_hash WHERE plaza_id = 1; 
-- 0.144 ms exec, 0.000091 ms plan

EXPLAIN ANALYZE VERBOSE SELECT * FROM mta_hash WHERE plaza_id > 10;
-- 160 ms exec, 0.104 ms plan

EXPLAIN ANALYZE VERBOSE INSERT INTO mta_hash VALUES (101, '2020-09-22', 23, 'I', 415, 422) 
-- 1.252 ms exec, 0.037 ms plan

EXPLAIN ANALYZE VERBOSE DELETE FROM mta_hash WHERE plaza_id = 101 AND 
														date = '2020-09-22' AND
														direction = 'I' AND
														vehicles_ez = 415 AND
														vehicles_cash = 422;
-- 0.054 ms exec, 0.075 ms plan

-------------------------------------------------------------------------
-- Ex 7 Which indexing algorithm and fields should be used, 
--      when the following queries happen often?
-------------------------------------------------------------------------
--a)
EXPLAIN ANALYZE VERBOSE
SELECT COUNT(*)
FROM mta_btree
WHERE hr = 23;

CREATE INDEX hr_btree ON mta_btree USING btree (hr);
CLUSTER mta_btree USING hr_btree;
-- exec time: 4.260 sec
-- b-tree is good to use here because it does equality and range search efficiently

EXPLAIN ANALYZE VERBOSE
SELECT COUNT(*)
FROM mta_btree
WHERE hr = 23;

DROP INDEX hr_btree;

--b
EXPLAIN ANALYZE VERBOSE
SELECT COUNT(*)
FROM mta_btree
WHERE hr > 17;

CREATE INDEX hr_btree ON mta_btree USING btree (hr);
CLUSTER mta_btree USING hr_btree;

EXPLAIN ANALYZE VERBOSE
SELECT COUNT(*)
FROM mta_btree
WHERE hr > 17;

DROP INDEX hr_btree;

--c
EXPLAIN ANALYZE VERBOSE
SELECT COUNT(*)
FROM mta_btree
WHERE hr > 17 and direction = 'I';

CREATE INDEX direction_hr_btree ON mta_btree USING btree (direction, hr);
CLUSTER mta_btree USING direction_hr_btree;

EXPLAIN ANALYZE VERBOSE
SELECT COUNT(*)
FROM mta_btree
WHERE hr > 17 and direction = 'I';

DROP INDEX direction_hr_btree;
--d
EXPLAIN ANALYZE VERBOSE
SELECT direction, hr, COUNT(*)
FROM mta_btree
WHERE hr > 17 
GROUP BY direction, hr;

CREATE INDEX hr_direction_btree ON mta_btree USING btree (hr, direction);
CLUSTER mta_btree USING hr_direction_btree;

EXPLAIN ANALYZE VERBOSE
SELECT direction, hr, COUNT(*)
FROM mta_btree
WHERE hr > 17 
GROUP BY direction, hr;

DROP INDEX hr_direction_btree;
