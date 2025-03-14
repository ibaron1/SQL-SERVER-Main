DECLARE @dropTbl VARCHAR(MAX) = (SELECT STRING_AGG(CONCAT('drop table ',SCHEMA_NAME(schema_id),'.',name),CHAR(13))
FROM sys.objects AS O
WHERE type='U' AND SCHEMA_NAME(schema_id) = 'test_history')

SELECT @dropTbl

EXEC (@dropTbl)