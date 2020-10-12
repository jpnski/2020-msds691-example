------------------------------------------------------------
--Ex 4. Create msds691 database.
------------------------------------------------------------
CREATE DATABASE msds691;

------------------------------------------------------------
--Ex 5. Create the Employees and Departments tables.
------------------------------------------------------------
CREATE TABLE employees
(
	eid INTEGER CHECK (eid > 0),
	name VARCHAR(20) NOT NULL,
	title VARCHAR(10) NOT NULL,
	ssn INTEGER DEFAULT NULL,
	PRIMARY KEY (eid),
	UNIQUE (ssn)
);

CREATE TABLE departments
(
	did INTEGER CHECK (did > 0),
	name VARCHAR(20) NOT NULL,
	PRIMARY KEY (did),
	UNIQUE (name)
);

------------------------------------------------------------
--Ex 6. Create the Works_In table.
------------------------------------------------------------
CREATE TABLE works_in
(
	did INTEGER CHECK (did > 0),
	eid INTEGER CHECK (eid > 0),
	since DATE DEFAULT CURRENT_DATE,
	PRIMARY KEY (did, eid),
	FOREIGN KEY (did) references departments (did) ON UPDATE CASCADE,
	FOREIGN KEY (eid) references employees (eid) ON UPDATE CASCADE
);

------------------------------------------------------------
--Ex 7. Insert data to Employees, Departments and Works_In.
------------------------------------------------------------
--Employees
----Diane as a manager
----Abigail as an engineer
------------------------------------------------------------
--Department
----Data Science
----Human Resources
------------------------------------------------------------
--Works_In
----Diane works at the Data Science department.
----Abigail works at HR.
------------------------------------------------------------

INSERT INTO employees VALUES (-1, 'Diane', 'manager');
INSERT INTO employees VALUES (1, NULL, 'manager');
INSERT INTO employees VALUES (1, 'Diane', 'mmmmmmmmmanager');
INSERT INTO employees VALUES (1, 'Diane', 'manager');
INSERT INTO employees VALUES (1, 'Abigail', 'engineer');
INSERT INTO employees VALUES (2, 'Abigail', 'engineer', 123456789);

INSERT INTO departments VALUES (1, 'Data Science'), (2, 'Human Resources');

INSERT INTO works_in VALUES (1,1), (2,2);

INSERT INTO works_in VALUES (4,3);




------------------------------------------------------------
--Ex 8. Load data from /Users/dwoodbridge/Class/2020_MSDS691/Data/employees.csv
------------------------------------------------------------
COPY employees 
FROM '/Users/dwoodbridge/Class/2020_MSDS691/Data/employees.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM employees;
SELECT * FROM departments;

------------------------------------------------------------
--Ex 9. Update department id from 1 to 2 from 2 to 3
-- TRY TO UPDATE department id from 3 to 4
------------------------------------------------------------
SELECT * FROM works_in;

UPDATE departments SET did = 3 WHERE did = 2;
UPDATE departments SET did = 2 WHERE did = 1;

SELECT * FROM works_in;

UPDATE works_in SET did = 4 WHERE did = 3;

------------------------------------------------------------
--Ex 10. Change since to start_date in the works_in table.
------------------------------------------------------------
ALTER TABLE works_in RENAME COLUMN since TO start_date;
SELECT * FROM works_in;

------------------------------------------------------------
--Ex 11. Delete the row where did = 2 in the works in table
--Delete the employees and departments tables. 
------------------------------------------------------------
DELETE FROM works_in WHERE did = 2;
SELECT * FROM works_in;
DELETE FROM departments WHERE did = 1; -- Won't work without ON DELETE CASCADE
ALTER TABLE works_in DROP CONSTRAINT works_in_did_fkey;
ALTER TABLE works_in ADD CONSTRAINT works_in_did_fkey FOREIGN KEY (did) REFERENCES departments (did) ON UPDATE CASCADE ON DELETE CASCADE;
DELETE FROM departments WHERE did = 1; 
SELECT * FROM works_in;


DROP TABLE employees CASCADE;
DROP TABLE departments CASCADE;
SELECT * FROM works_in;
DROP TABLE works_in;
