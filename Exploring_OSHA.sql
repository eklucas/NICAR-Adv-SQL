/* 

Below are the SQL commands used for Advanced SQL for analysis at NICAR15
These commands were written in MySQL.

This data was downloaded from the DOL Data Catalog: http://ogesdw.dol.gov/views/data_catalogs.php
on 02/23/2015. The csv files attached to this project are unaltered; in the osha_safety.sql database (the data we're running these queries on) the inspection table has been sliced to exclude everything prior to 2000 (using the field open_date). 

*/

--#################    KNOW THY DATA.    #################### 

-- How many records in the inspection table? 

SELECT count(*)
FROM inspection
;

-- 1,568,759 inspection records

-- Check for any dupes - two or more records that are exactly the same

SELECT DISTINCT * -- MySQL won't let us do count(DISTINCT *), but we'll get to an easier way to do this later on. 
FROM inspection
LIMIT 2000000
;
-- No exact duplicates, which is good. Exact duplicates are not necessarily errors, but it's good to know that they are there. 

-- What's the date range? 

SELECT open_date
FROM inspection
ORDER BY 1
LIMIT 10
;
-- then add desc to your ORDER BY 

-- The activity_nr here is supposed to be a unique identifier; we'll use it to join to other tables later. Let's check to make sure it's not duplicated: 

SELECT activity_nr, count(*)
FROM inspection
GROUP BY 1
HAVING count(*) > 1
;
-- Good, no duplicates in our unique identifier. 

-- I usually do some truthing on something like a state field: is it relatively clean, or are there are bunch of crazy entries? Can be a good indication of how clean or dirty your data is: 

SELECT site_state, count(*)
FROM inspection
GROUP BY 1
;

-- Overall looks pretty good. Some blanks, but no entries that I don't recognize. We could look into the blanks to see if there's an obvious reason for them. 

SELECT *
FROM inspection
WHERE site_state = ''
;

--##############   CLEAN IT UP, PREP FOR ANALYSIS   ##################

-- Because the record layout is pretty useless for this database, I impored everything as text. But there are date fields in here that we probably want to use as date fields. 

-- So let's create a new field that is actually formatted as a date. 

ALTER TABLE inspection ADD COLUMN open_date2 varchar(255) AFTER open_date
;

-- Then we'll populate it with data from the `open_date` field, but after we convert it to a date. 

UPDATE inspection SET open_date2 = str_to_date(open_date, '%Y-%m-%d')
;

-- Now we'll check our work: 
SELECT open_date, open_date2, COUNT(*)
FROM inspection
GROUP BY 1, 2
;

-- Now we can put that date field to use: 

SELECT year(open_date2), count(*)
FROM inspection 
GROUP BY 1
ORDER BY 2 desc
;

select min(open_date2), max(open_date2)
FROM inspection
;

-- Let's do this for the close_case_date as well:

ALTER TABLE inspection ADD COLUMN close_case_date2 varchar(255) AFTER close_case_date
;

UPDATE inspection SET close_case_date2 = str_to_date(close_case_date, '%Y-%m-%d')
;

SELECT close_case_date, close_case_date2, COUNT(*)
FROM inspection
GROUP BY 1, 2
;

SELECT year(close_case_date2), count(*)
FROM inspection
GROUP BY 1
ORDER BY 2 desc
;

-- Now, how long was the longest case open? 

SELECT datediff(close_case_date2, open_date2)
FROM inspection
ORDER BY 1 desc
;

-- Translate that to years (roughly):

SELECT datediff(close_case_date2, open_date2)/365
FROM inspection
ORDER BY 1 desc
;

-- Let's pull out inspections relating to the United States Postal Service, just to flex our filter muscles:

SELECT estab_name, count(*)
from inspection
WHERE estab_name LIKE '%u%s%postal%service%' OR estab_name LIKE '%USPS%'
GROUP BY 1
;

-- There's one establishment we probably want to exclude in this list: "HIRUTS FLOWERS AND POSTAL SERVICE"

SELECT estab_name, count(*)
FROM inspection
WHERE (estab_name LIKE '%u%s%postal%service%' OR estab_name LIKE '%USPS%') AND estab_name <> 'HIRUTS FLOWERS AND POSTAL 	SERVICE'
;

-- Now we'll take a look at the inspections that are connected with accident. There's a helpful field near the end called osha_accident_indicator, which (according to the record layout) has the values: 1, blank.

SELECT osha_accident_indicator, count(*)
FROM inspection
GROUP BY 1
;

-- 55,279 have been flagged as being associated with an accident. 

-- To explore information about the accidents, we'll have to bring a additional data specifically on accidents. 
-- Take a look at the accident table (using the Table Data tab in SQLYog)

-- This table has great stuff, like the event description. If we start digging into particular accidents, we're going to want this field. But the inspection table holds most of the crucial meta data, like where the accident took place. So we need both tables. But notice that there's no activity_nr field in this data. How will we join the two? 
-- To save time I'll just tell you: these tables both join to a third table, the accident_injury table. So let's get that in here. 

-- First, create the table: 

CREATE TABLE accident_injury (
summary_nr varchar(255),
rel_insp_nr varchar(255),
age varchar(255),
sex varchar(255),
nature_of_inj varchar(255),
part_of_body varchar(255),
src_of_injury varchar(255),
event_type varchar(255),
evn_factor varchar(255),
hum_factor varchar(255),
occ_code varchar(255),
degree_of_inj varchar(255),
task_assigned varchar(255),
hazsub varchar(255),
const_op varchar(255),
const_op_cause varchar(255),
fat_cause varchar(255),
fall_distance varchar(255),
fall_ht varchar(255),
injury_line_nr varchar(255)
);

-- Then import the data: 

LOAD DATA LOCAL INFILE 'C:\\training\\Adv_SQL\\MySQL\\osha_accident_injury.csv'
INTO TABLE accident_injury
FIELDS TERMINATED BY ','    -- delimiter
OPTIONALLY ENCLOSED BY '"'  -- text qualifier
ESCAPED BY '"'              -- this is optional, but you should figure out what the escape character is, usually '\\'
IGNORE 1 LINES;             -- if there's a header row, you don't want to import it as data

-- Do a quick check of your data: how many records? What's in it? 

-- I usually truth my joins a little bit before proceeding with analysis. 

SELECT count(*)
FROM inspection as a
JOIN accident_injury as b
ON a.activity_nr = b.rel_insp_nr

-- If our count is zero, we'll know the join didn't work. 

-- Also, for every inspection that was flagged with the accident indicator, there should be at least one record in accident_injury. Is that true?
-- This query looks for any records that DO have the accident flag but DON'T have a matching record in accident_injury: 

SELECT a.*
FROM inspection as a
LEFT JOIN accident_injury as b
ON a.activity_nr = b.rel_insp_nr
WHERE b.rel_insp_nr is null and a.osha_accident_indicator = 't'

-- Looks good. 
-- Now let's bring the three tables together: 

SELECT COUNT(*)
FROM inspection AS a
JOIN accident_injury AS b
ON a.activity_nr = b.rel_insp_nr
JOIN accident AS c
ON b.summary_nr = c.summary_nr

-- I tested this join without indexes and it took 13 min 29 sec
-- With indexes: < 1 sec
-- Result: 132,201

-- Circling back to that count distinct records: You can write a subquery selecting all the DISTINCT records, and then query those results with a COUNT(*):

select count(*)
from (  select distinct *
		from inspection   ) as temp -- if you use a subquery in ( ) you have to give it a name using 'as'; call it whatever you like.
;

-- Another handy way of putting subqueries to good use is actually creating a summary number for a particular feature in your database and then joining that query back to the original table: 

SELECT a.*, b.estab_count
FROM inspection as a
JOIN (SELECT estab_name, count(*) as estab_count
		FROM inspection
		GROUP BY 1) as b
ON a.estab_name = b.estab_name 

-- Now for every record in your inspection table, you have a total record count for the establishment associated with that inspection. 
