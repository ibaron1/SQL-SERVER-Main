-- DDL and sample data population, start
DECLARE @tbl TABLE (id INT IDENTITY PRIMARY KEY, col1 CHAR(1), col2 CHAR(1), col3 CHAR(1), col4 CHAR(1));
INSERT INTO @tbl (col1, col2, col3, col4) VALUES
( 'A', 'B', NULL, 'D'),
(NULL, 'E' , 'F' , 'G'),
(NULL, NULL, NULL , NULL);

SELECT id, REPLACE((
SELECT *
FROM @tbl AS c
WHERE c.id = p.id
FOR XML PATH('r'), TYPE, ROOT('root')
).query('data(/root/r/*[local-name() ne "id"])').value('.', 'VARCHAR(100)'), SPACE(1), '|') AS concatColumns
FROM @tbl AS p;

DECLARE @ORDINAL_POSITION INT, @Max_ORDINAL_POSITION INT;
DECLARE @sqlstr VARCHAR(MAX) = 'SELECT CAST(''id'' as char(2)) as id, ';

SELECT @ORDINAL_POSITION = MIN(C.ORDINAL_POSITION),
@Max_ORDINAL_POSITION = MAX(C.ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS AS C
WHERE C.TABLE_SCHEMA = 'DataMart' AND C.TABLE_NAME = 'Loan'
AND C.COLUMN_NAME NOT IN ('RecordStartDate','RecordEndDate' )

WHILE @ORDINAL_POSITION <= @Max_ORDINAL_POSITION
BEGIN

SELECT @sqlstr += CONCAT('CAST(''',C.COLUMN_NAME,''' AS VARCHAR(100)) AS Col',@ORDINAL_POSITION ,IIF(@ORDINAL_POSITION < @Max_ORDINAL_POSITION,',',' into ##t'))
FROM INFORMATION_SCHEMA.COLUMNS AS C
WHERE C.TABLE_SCHEMA = 'DataMart' AND C.TABLE_NAME = 'Loan'
AND C.COLUMN_NAME NOT IN ('RecordStartDate','RecordEndDate')
and ORDINAL_POSITION = @ORDINAL_POSITION;

SET @ORDINAL_POSITION += 1;

END;

EXEC (@sqlstr);

--=========================================================================================================

SELECT * FROM ##t

SELECT id, REPLACE((
SELECT *
FROM ##t AS C
WHERE c.id = p.id
FOR XML PATH('r'), TYPE, ROOT('root' )
).query('data(/root/r/*[local-name() ne "id"])').value('.', 'VARCHAR(max)') , SPACE(1), '|') AS concatColumns
FROM ##t AS p;