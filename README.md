Data and Materials for Advanced SQL in MySQL at NICAR15
======================

###All the SQL for the class is in this file: [Exploring_OSHA.sql](https://github.com/eklucas/NICAR-Adv-SQL/blob/master/Exploring_OSHA.sql)

###Download the data 
https://www.dropbox.com/s/fw09f9kxi0ldir3/adv_sql_data.zip?dl=0

`inspection`, `accident`, `accident_injury` were downloaded from the DOL's [OSHA download site](http://ogesdw.dol.gov/views/data_catalogs.php) on 02/23/2015.


###Record layouts
*Note that the data dictionary provided by OSHA doesn't list all of the fields that are in the data*
 * [Data dict from OSHA](http://enforcedata.dol.gov/views/data_dictionary.php)
 * [inspection](https://github.com/eklucas/NICAR-Adv-SQL/blob/master/inspection_layout.csv)
 * [accident](https://github.com/eklucas/NICAR-Adv-SQL/blob/master/accident_layout.csv)
 * [accident_injury](https://github.com/eklucas/NICAR-Adv-SQL/blob/master/accident_injury_layout.csv).

###What I cover: 
* Truthing data tables and joins
* `DISTINCT`
* `CREATE TABLE` and `LOAD DATA INFILE` syntax
* `ALTER TABLE` to add columns
* `UPDATE` to populate new columns
* `STR_TO_DATE` to convert text dates to actual dates
* `DATEDIFF` to calculate difference in days between two dates
* wildcards for more complex filtering
* aliases in table names
* outer joins
* multiple joins in one query
* subqueries
