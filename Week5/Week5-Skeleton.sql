DROP TABLE IF EXISTS nytimes_bestsellers;

--Ex 1. Create a table nytimes_bestsellers and insert nyt_bestsellers.json
-- What is the column type?

CREATE TABLE nytimes_bestsellers(bestseller JSON);
COPY nytimes_bestsellers FROM '/data/nyt_bestsellers.json';
SELECT * FROM nytimes_bestsellers;
SELECT pg_typeof(bestseller) FROM nytimes_bestsellers;

--Ex 2. From nytimes_bestsellers,
-- A. Return oid, author and amazon_url ordered by author name and oid.

SELECT bestseller -> '_id' FROM nytimes_bestsellers; -- returns the json key/value pair
SELECT bestseller -> '_id' ->> '$oid' FROM nytimes_bestsellers; -- returns the value as text

SELECT
bestseller -> '_id' ->> '$oid' AS oid, 
bestseller ->> 'author' AS author,
bestseller ->> 'amazon_product_url' AS url
FROM nytimes_bestsellers
ORDER BY author ASC, oid ASC;

-- B. Return the number of books written by "Alan Furst” in the table.

SELECT count(*) FROM nytimes_bestsellers WHERE bestseller ->> 'author'='Alan Furst';

-- (create table for example 3)
--- Week4 mta_no_index table.
DROP TABLE IF EXISTS mta_no_index; 

CREATE TABLE mta_no_index (
	plaza_id INTEGER,
	date DATE,
	hr INTEGER,
	direction VARCHAR(1),
	vehicle_ez INTEGER,
	vehicle_cash INTEGER
);

COPY mta_no_index FROM '/data/NY_MTA.csv' CSV HEADER;


--Ex 3. Create rows of JSON include date, the total number of vehicle_ez and the total number of vehicle_cash per date.
-- Use the mta table from Week3.
--Order it by date (ASC)

SELECT to_json(daily_vehicle_summary) FROM
(SELECT date, SUM(vehicle_ez) AS sum_ez, sum(vehicle_cash) AS sum_cash
FROM mta_no_index
GROUP BY date
ORDER BY date ASC) AS daily_vehicle_summary


--Ex 4. 
-- Percentage of cash made by hour per plaza on November 10, 2016 (Inbound only).
-- 1) without window function

SELECT mta_no_index.plaza_id, hr, (CAST(vehicle_cash AS REAL)/total_cash)*100 AS percentage_cash
FROM mta_no_index
JOIN
(SELECT plaza_id, SUM(vehicle_cash) AS total_cash
FROM mta_no_index
WHERE date='2016-11-10' AND direction='I'
GROUP BY plaza_id) AS agg_mta
ON
	mta_no_index.plaza_id = agg_mta.plaza_id AND
	mta_no_index.date='2016-11-10' AND
	mta_no_index.direction='I'
ORDER BY plaza_id, hr;

-- 2) with windows function

SELECT plaza_id, hr, 100*(CAST(vehicle_cash AS REAL)/SUM(vehicle_cash)) OVER
(PARTITION BY plaza_id)
FROM mta_no_index
WHERE date='2016-11-10' AND direction='I'
ORDER BY plaza_id ASC, hr ASC;

-- demonstrating using window frame clauses with partitions:

SELECT plaza_id, hr, vehicle_cash, 
	   SUM(hr) OVER(), 
	   SUM(hr) OVER (PARTITION BY plaza_id), 
	   SUM(hr) OVER (PARTITION BY plaza_id ORDER BY hr),
	   SUM(hr) OVER (PARTITION BY plaza_id ORDER BY hr ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING),
	   SUM(hr) OVER (PARTITION BY plaza_id ORDER BY hr ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
	   SUM(hr) OVER (PARTITION BY plaza_id ORDER BY hr ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM mta_no_index
WHERE date = '2016-11-10' AND direction = 'I'
ORDER BY plaza_id, hr;


--Ex 5. Calculate correlation between the absolute hourly change in vehicle paying cash
-- and the absolute hourly change in vehicles paying by EZ-pass?

SELECT CORR(ez_diff, cash_diff) FROM (
SELECT plaza_id, date, hr, vehicle_ez, vehicle_cash,
	abs(LAG(vehicle_ez) OVER (PARTITION BY plaza_id ORDER BY date, hr) - vehicle_ez) AS ez_diff,
	abs(LAG(vehicle_cash) OVER (PARTITION BY plaza_id ORDER BY date, hr) - vehicle_cash) AS cash_diff
FROM mta_no_index
WHERE direction='I') AS diff

--Ex 6. 
-- a Find the most common color of boat reserved for each sailor's name ordered by sid.
-- (If a sailor never reserved a boat, the color and max column should be NULL.)

SELECT * FROM sailors;

-- thought process:
	-- partition by sid, use window function to get first row value when sorting by count, descending
	-- will return highest counts of boat color for each sid
	-- then join that with sailors table to get remaining info for question

SELECT sailors.sid, color, count FROM sailors 
LEFT JOIN(
	SELECT DISTINCT(FIRST_VALUE(sid) OVER(PARTITION BY sid ORDER BY count DESC)) AS sid,
	FIRST_VALUE(color) OVER(PARTITION BY sid ORDER BY count DESC) AS color,
	FIRST_VALUE(count) OVER(PARTITION BY sid ORDER BY count DESC) AS count
	FROM
		(SELECT sid, color, COUNT(*) FROM reserves
		JOIN boats
		ON reserves.bid = boats.bid
	GROUP BY sid, color) AS sid_color_count) 
	AS sid_max_color_count
ON sailors.sid = sid_max_color_count.sid
ORDER BY sid;

--b For each boat id, calculate the cumulative number of reservations.
	-- note: count(*) == row_number() here
	
SELECT bid, day, row_number() OVER(PARTITION BY bid ORDER BY day)
FROM reserves

--Ex 7. We are interested in how many unique sailors reserved a boat each year along with how
-- many reservation was made quarterly.
-- The output should have cohort(1st day of the year), the number of unique sailors, reservation
-- made between Jan-Mar, Apr-Jun, Jul-Sep and Oct-Dec.

SELECT year_sid_count.year AS cohort, count, mon_1_3, mon_4_6, mon_7_9, mon_10_12 FROM
	(SELECT COUNT(*), year FROM(
		SELECT DISTINCT sid, EXTRACT(YEAR FROM day) AS year
		FROM reserves) AS yearly_unique_sid
		GROUP BY year) AS year_sid_count
	JOIN
	(SELECT year, SUM(mon_1_3) as mon_1_3,
	 			  SUM(mon_4_6) AS mon_4_6,
	 			  SUM(mon_7_9) AS mon_7_9,
	 			  SUM(mon_10_12) AS mon_10_12
	 FROM (
		SELECT EXTRACT(YEAR FROM first_res_month) AS year,
		CASE WHEN EXTRACT(MONTH FROM first_res_month)<=3 THEN count END AS mon_1_3,

		CASE WHEN EXTRACT(MONTH FROM first_res_month)>=4 AND
			EXTRACT(MONTH FROM first_res_month)<=6 THEN count END AS mon_4_6,

		CASE WHEN EXTRACT(MONTH FROM first_res_month)>=7 AND
			EXTRACT(MONTH FROM first_res_month)<=9 THEN count END AS mon_7_9,

		CASE WHEN EXTRACT(MONTH FROM first_res_month)>=10 AND
			EXTRACT(MONTH FROM first_res_month)<=12 THEN count END AS mon_10_12
		FROM
			(SELECT DISTINCT
			FIRST_VALUE(day) OVER(PARTITION BY EXTRACT(YEAR FROM day), EXTRACT(MONTH FROM day)) AS first_res_month,
			COUNT(*) OVER(PARTITION BY EXTRACT(YEAR FROM day), EXTRACT(MONTH FROM day))
			FROM reserves) AS first_res_month_count
			) AS monthly_res_count
		GROUP BY year) AS quarterly_reserve_count
	ON quarterly_reserve_count.year = year_sid_count.year
	
	
--Ex 8
--a)Create a CTE called mta_inbound_vehicle which returns date, vehicle_cash and vehicle_ez for
-- inbound only traffics.
--Return date, daily total of vehicle_cash and daily total of vehicle_ez ordered by date.

WITH mta_inbound AS
(
	SELECT date, vehicle_cash, vehicle_ez
	FROM mta_no_index
	WHERE direction = 'I'
)
SELECT date, sum(vehicle_cash), sum(vehicle_ez)
FROM mta_inbound
GROUP BY date
ORDER BY date;

	-- results in a simpler to understand query by using CTE

--b) Create a CTE called plaza_cumulative_hourly_vehicle_counts which returns date, hr, plaza_id,
-- vehicle_ez, vehicle_cash,  and the cumulative sum of vehicle_ez  and the cumulative sum of
-- vehicle_cash for the corresponding plaza_id for date. 
-- Return values when hr is 12.

WITH plaza_cumulative AS
(
	SELECT plaza_id, date, hr, vehicle_ez, vehicle_cash,
	SUM(vehicle_ez) OVER(PARTITION BY plaza_id, date ORDER BY hr) AS vehicle_ez_sum,
	SUM(vehicle_cash) OVER(PARTITION BY plaza_id, date ORDER BY hr) AS vehicle_cash_sum
	FROM mta_no_index
	WHERE direction = 'I'
	ORDER BY plaza_id, date, hr
)
SELECT *
FROM plaza_cumulative
WHERE hr = 12;


-- Ex 9. In mta_no_index table, calculate  most common color of boat reserved for each sailor's name
-- ordered by sid using CTE. 
-- Then, only return values for “Horatio”.


--Version 1)



--Version 2)

WITH sid_name AS
(
	SELECT sid, sname FROM sailors
),
sid_color_count AS
(
	SELECT sid, color, COUNT(*) FROM reserves
	JOIN boats
	ON reserves.bid = boats.bid
	GROUP BY sid, color
),
sid_common_color_count AS
(
	SELECT sname, sailors.sid, color, count
	FROM sailors
	JOIN
	(		
		SELECT DISTINCT FIRST_VALUE(sid) OVER(PARTITION BY sid ORDER BY count DESC) AS sid,
		FIRST_VALUE(color) OVER(PARTITION BY sid ORDER BY count DESC) AS color,
		FIRST_VALUE(count) OVER(PARTITION BY sid ORDER BY count DESC) AS count
		FROM sid_color_count
	) AS sid_max_color_count
	ON sid_max_color_count.sid = sailors.sid
)
SELECT *
FROM sid_common_color_count
WHERE sname = 'Horatio'


-- example: creating a user defined function
CREATE OR REPLACE FUNCTION increment(input INTEGER) 
RETURNS INTEGER AS 
$$ SELECT input + 1 $$ 
LANGUAGE SQL;

SELECT * FROM increment(42);

DROP FUNCTION IF EXISTS increment;


-- Ex 10. In mta_no_index table, calculate  most common color of boat reserved for each sailor's name
-- ordered by sid using functions and CTE. 
-- Then, only return values for “Horatio”.
-- In order to improve the search time, filter out the name first using a function.


--Ex 11.
DROP VIEW IF EXISTS plaza_1_mta;

-- A. Create a view called plaza_1_mta for all the records where plaza_id is 1.

-- B. How many rows are in plaza_1_mta?

-- C. Insert (1, '2020-11-13', 9, 'O', 500, 400)  into plaza_1_mta.
-- How many rows are in plaza_1_mta?

-- D. In plaza_1_mta, update plaza_id to 2 where date = '2010-01-01' AND hr = 7 AND direction = ‘O’.
-- How many rows are in plaza_1_mta?

-- How to avoid this?

--E. Drop the mta_no_index table.

