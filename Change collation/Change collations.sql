/*
To change the collation settings
•	Restrict the Database access to Single User Mode
This will only change the collation of the Database and not the collation of the Database objects (Tables) if any exists already. We need to explicitly change the collation of the character (VARCHAR / NVARCHAR) columns for each table. To change the collation settings for columns
•	Take the backup of all the Indexes and constraints of the tables with Character columns in the Database
•	Drop all the Indexes and constraints (Primary Key, Foreign Key, Defaults etc)
•	Change the Collation setting for the table columns. The below script can be used to generate the script that identifies the character columns and replace it with the new collation in the Database
•	Note:  If the COLLATE clause is not specified, changing the data type of a column will cause a collation change to the default collation of the database.
Generate change collation
*/
-- all tables

SELECT 'ALTER TABLE ' + schema_name(o.schema_id)+'.'+o.name + ' ALTER COLUMN '+'['+c.name+'] '+
CASE WHEN t.name in('sysname') then t.name
ELSE t.name + '(' + 
	CASE c.max_length WHEN  -1 then 'max' else RTRIM(CONVERT(CHAR,c.max_length)) END +') ' + 
	' COLLATE SQL_Latin1_General_CP1_CI_AS' END + CASE c.is_nullable  WHEN 0 THEN ' NOT NULL' ELSE ' NULL' END+ ';' 

FROM sys.columns c, sys.objects o, sys.types t
WHERE c.object_id = o.object_id 
AND o.type = 'U'
AND t.user_type_id = c.user_type_id 
AND c.collation_name IS NOT NULL


-- 1 table

SELECT 'ALTER TABLE ' + schema_name(o.schema_id)+'.'+o.name + ' ALTER COLUMN '+'['+c.name+'] '+
t.name + '(' + 
CASE c.max_length WHEN  -1 then 'max' else RTRIM(CONVERT(CHAR,c.max_length)) end +') ' + 
' COLLATE Latin1_General_CI_AS ' + CASE c.is_nullable  WHEN 0 THEN 'NOT NULL' ELSE 'NULL' End +
+ ';'
FROM sys.columns c, sys.objects o, sys.types t
WHERE c.object_id = o.object_id 
AND o.type = 'U' and o.name = 'user_tbl'
AND t.user_type_id = c.user_type_id 
AND c.collation_name IS NOT NULL


-- 1 column
ALTER TABLE user_tbl
ALTER COLUMN userid varchar(10) COLLATE Latin1_General_CI_AS 

•	Change the Database collation using the following syntax.

ALTER DATABASE dbname COLLATE [Replace Actual Collation]
GO
Execute generated change collation for table columns
