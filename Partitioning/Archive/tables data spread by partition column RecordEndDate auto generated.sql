
/*
SELECT 'DataMart_History.Loan' AS tbl,
$PARTITION.pf_DateByMonthRight(RecordEndDate) as partition#, COUNT(1) as rows#
FROM DataMart_History.Loan
GROUP by
$PARTITION.pf_DateByMonthRight(RecordEndDate)
HAVING count(1)>1;
*/
-- MAIN
DECLARE @sql VARCHAR(MAX) = '';

SELECT @sql += CONCAT('SELECT ''', SCHEMA_NAME(schema_id),'.', name,''' as tbl, RecordEndDate, $PARTITION.pf_DateByMonthRight(RecordEndDate) as partition#, COUNT(1) as rows# from ',
SCHEMA_NAME (schema_id),'.', name,' group by RecordEndDate, $PARTITION.pf_DateByMonthRight(RecordEndDate) having count(1)>1;', CHAR(13))
FROM sys.objects
WHERE type='U' AND SCHEMA_NAME(schema_id) = 'DataMart_History'

SELECT @sql
EXEC @sql

GO
