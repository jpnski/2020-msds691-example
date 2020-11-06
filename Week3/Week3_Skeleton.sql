------------------------------------------------------------
--Ex 1. Create the sailors, boats, and reserves tables.
------------------------------------------------------------

CREATE TABLE IF NOT EXISTS sailors (
	sid integer PRIMARY KEY,
	sname varchar(30),
	rating integer CHECK (rating >= 0),
	age REAL);

CREATE TABLE IF NOT EXISTS boats(
	bid integer PRIMARY KEY,
	bname varchar(30),
	color varchar(20)
);

CREATE TABLE IF NOT EXISTS reserves (
	sid integer,
	bid integer,
	day DATE,
	PRIMARY KEY (sid,bid,day),
	FOREIGN KEY (sid) REFERENCES sailors (sid) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (bid) REFERENCES boats (bid) ON UPDATE CASCADE ON DELETE CASCADE
);

-- copy csv data from data path

COPY sailors FROM '/data/sailors.csv' CSV HEADER;
COPY boats FROM '/data/boats.csv' CSV HEADER;
COPY reserves FROM '/data/reserves.csv' CSV HEADER;

-- check copied data

SELECT * FROM sailors;
SELECT * FROM boats;
SELECT * FROM reserves;

------------------------------------------------------------
-- Ex 2. return sid, boat color (101 - blue, 103 - green, others are red) along with day
-- from the reserves table.
------------------------------------------------------------

SELECT sid, 
CASE
	WHEN bid = 101 THEN 'blue'
	WHEN bid = 103 THEN 'green'
	ELSE 'red'
END 
AS color, day FROM reserves;

------------------------------------------------------------
-- Ex 3.
------------------------------------------------------------
-- A. Find the names of sailors who have reserved boat 103.
SELECT sname FROM sailors WHERE sid IN(
	SELECT sid FROM reserves WHERE bid = 103);

-- B. Find the names of sailors who have not reserve a red boat.
SELECT sname from sailors WHERE sid NOT IN(
	SELECT DISTINCT sid FROM reserves WHERE bid IN(
		SELECT bid FROM boats WHERE color = 'red'));

------------------------------------------------------------
-- Ex 4. Find the names of sailors who have reserved boat number 103.
------------------------------------------------------------

SELECT sname FROM sailors WHERE EXISTS(
	SELECT * FROM reserves WHERE bid = 103 AND sid = sailors.sid);

------------------------------------------------------------
-- Ex 5.
------------------------------------------------------------
-- A. Find sailors whose rating is better than every sailor called Horatio.

SELECT * FROM sailors WHERE rating > ALL(
	SELECT rating FROM sailors WHERE sname = 'Horatio');

-- B. Find sailors whose rating is better than some sailor called Horatio.

SELECT * FROM sailors WHERE rating > ANY(
	SELECT rating FROM sailors WHERE sname = 'Horatio');

-- C. Find the names of sailors who have reserved all boats.
SELECT sname FROM sailors WHERE NOT EXISTS(
	SELECT DISTINCT bid FROM boats EXCEPT(
		SELECT bid FROM reserves WHERE sid = sailors.sid));

------------------------------------------------------------
-- Ex 6.
------------------------------------------------------------
-- A. Find the average age of all sailors with a rating of 10.

SELECT AVG(age) FROM sailors WHERE rating = 10;

-- B. Find the name and age of the oldest sailor.

SELECT sname, age from sailors WHERE age =(SELECT MAX(age) FROM sailors);

-- C. Count the number of different sailor names.

SELECT COUNT(DISTINCT sname) from sailors;

-- D. Find the names of sailors who are older than the oldest sailor with a rating of 10.

SELECT sname FROM sailors WHERE age > (SELECT MAX(age) FROM sailors WHERE rating = 10);

------------------------------------------------------------
-- Ex 7.
------------------------------------------------------------
-- A. Find the age of the youngest sailor who is eligible to vote (at least 18 years old) for
-- each rating level with at least two such sailors.


SELECT rating, MIN(age) FROM sailors WHERE age >= 18 GROUP BY(rating) HAVING COUNT(*) >= 2;

-- B. Find the average age of sailors who are of voting age for each rating level that has at
-- least two such sailors.

SELECT rating, AVG(age) FROM sailors WHERE age >= 18 GROUP BY(rating) HAVING COUNT(*) >= 2;

-- C. Find those ratings for which the average age of sailors is the minimum over all ratings.

SELECT rating, AVG(age) FROM sailors GROUP BY (rating) HAVING AVG(age) = (
	SELECT MIN(avg_age) FROM (
		SELECT AVG(age) as avg_age FROM sailors GROUP BY(rating)) AS group_avg_age);

-- D. For each red boat, find the number of reservations for this boat.


------------------------------------------------------------
-- Ex 8. We want to see monthly trend of the reservation between August and December. 
-- You can assume that there are data from several years.
-- Create a table that has August, September, October, November and December.
-- Rows should be the number of reservation made.
-- If there is no reservation record, it should be 0.
------------------------------------------------------------

SELECT month, COUNT(*) FROM(
	SELECT EXTRACT(MONTH FROM day) AS month FROM reserves) as reserve_month
	WHERE month >= 8 GROUP BY month;

------------------------------------------------------------
-- Ex 9.  We want to see monthly trend of the reservation between August and December per year. 
-- You can assume that there are data from several years.
-- Create a table that has August, September, October, November and December.
-- Rows should be the number of reservation made of each year, where the first column is year.
-- If there is no reservation record, it should be 0.
------------------------------------------------------------


------------------------------------------------------------
-- Ex 10.
------------------------------------------------------------
-- A. For each red boat, find the number of reservations for this boat.

-- B. For each sailor id, find the number of reservations.

-- C. Find the possible sailor id and boat id combinations.

-- D. Find all possible sailor id and boat id combinations and the reserved dates. 
----- (If the sailor never reserved the boat, its date is NULL)


------------------------------------------------------------
-- Ex 11.
------------------------------------------------------------
-- A. Find the most common color of boat reserved for each sailor's name order by sid.
-- (If a sailor never reserved a boat, the color and max column should be NULL.)

-- B. For each boat id, calculate the cumulative number of reservations.


------------------------------------------------------------
-- Ex 12. We are interested in how many unique sailors reserved a boat each year along with how many reservation was made quarterly.
-- The output should have cohort(1st day of the year), the number of unique sailors, reservation made between Jan-Mar, Apr-Jun, Jul-Sep and Oct-Dec.
------------------------------------------------------------
