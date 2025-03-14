SET NOCOUNT ON

DECLARE @tbl VARCHAR(MAX)
,@tblName varchar(200)='Loan' -- null -- > must be in loop for all tables
,@schema varchar(100)='DataMart'

SELECT @tbl = CONCAT(
'create table ',@schema,'.',@tblName,CHAR(13)
,'(')

SELECT @tbl +=
STRING_AGG(CAST(CONCAT(COLUMN_NAME,' '
		,DATA_TYPE
		,CASE	WHEN DATA_TYPE NOT LIKE '%int'
				THEN CONCAT(IIF(CHARACTER_MAXIMUM_LENGTH IS NULL, '', '('+CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(100))+')')
							,IIF(NUMERIC_PRECISION IS NULL, '', '('+CAST(NUMERIC_PRECISION AS VARCHAR(100))+','+CAST(NUMERIC_SCALE AS VARCHAR(2))+')'))
		END
		,IIF(IS_NULLABLE = 'YES' ,' NULL', ' NOT NULL')
		,IIF(COLUMN_DEFAULT IS NULL,'', CONCAT(' DEFAULT(''',COLUMN_DEFAULT,''')' ))
		,CHAR(13)
) AS VARCHAR(MAX)),
',')WITHIN GROUP(ORDER BY ORDINAL_POSITION)
FROM INFORMATION_SCHEMA. COLUMNS
WHERE TABLE_SCHEMA=@schema AND (TABLE_NAME = @tblName OR @tblName IS NULL)

SELECT @tbl = CONCAT(@tbl,')',CHAR(13),';');

SELECT @tbl += CreateIndexSOL
FROM Utilities.TableIndexes
WHERE SchemaName = @schema
AND tablename = @tblName

SELECT @tbl



