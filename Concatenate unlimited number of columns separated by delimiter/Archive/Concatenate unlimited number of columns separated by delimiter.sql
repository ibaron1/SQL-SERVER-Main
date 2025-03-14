https://stackoverflow.com/questions/56198460/how-to-stop-the-insertion-of-default-date-format-1900-01-01-in-sql-server-when-u

insert into t (datecol)
    values (nullif('', ''));

to make a value NULL

-------------------------------------------------------

https://stackoverflow.com/questions/65924066/concatenate-or-merge-many-columns-values-with-a-separator-between-and-ignoring-n/65924097#65924097

Concatenate or merge many columns values with a separator between and ignoring nulls - SQL Server 2016 or older
---------------------------------------------------------------------------------------------------------------

Function concat_ws is limited from min 3 to max 254 columns

Below code is for unlimited number of columns dynamically generated string

Here is another method by using XML and XQuery.

The number of columns is not hard-coded, it could be dynamic.

SQL

-- DDL and sample data population, start
DECLARE @tbl TABLE (id INT IDENTITY PRIMARY KEY, col1 CHAR(1), col2 CHAR(1), col3 CHAR(1), col4 CHAR(1));
INSERT INTO @tbl (col1, col2, col3, col4) VALUES
( 'A',  'B',  NULL, 'D'),
(NULL, 'E' , 'F'  , 'G'),
(NULL, NULL, NULL , NULL);
-- DDL and sample data population, end

DECLARE @separator CHAR(1) = '|';

SELECT id, REPLACE((
    SELECT * 
    FROM @tbl AS c
    WHERE c.id = p.id
    FOR XML PATH('r'), TYPE, ROOT('root')
).query('data(/root/r/*[local-name() ne "id"])').value('.', 'VARCHAR(100)') , SPACE(1), @separator) AS concatColumns
FROM @tbl AS p;