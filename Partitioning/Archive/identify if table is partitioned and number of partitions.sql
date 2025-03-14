-- returns all partitions
SELECT DISTINCT CONCAT(SCHEMA_NAME(T.schema_id),'.',T.name) AS tableName,
P.partition_number
FROM sys.partitions AS P
INNER JOIN sys. tables AS T
ON T.object_id = P.object_id
WHERE SCHEMA_NAME(T. schema_id) = 'DataMart_History'

-- checks if table is partitioned - if not will return only partition = 1 ; for > 1 check will return empty result set
SELECT DISTINCT CONCAT(SCHEMA_NAME(T.schema_id),'.',T.name) AS tableName,
P.partition_number
FROM sys.partitions AS P
INNER JOIN sys. tables AS T
ON T.object_id = P.object_id
WHERE SCHEMA_NAME(T.schema_id) = 'DataMart_History'
AND T.name = 'PaymentChangeHistory'
AND P.partition_number > 1

SELECT count(DISTINCT P.partition_number)
FROM sys.partitions AS P
WHERE P.object_id = OBJECT_ID('DataMart_History.Bankruptcy')

DECLARE @DeltaTableName VARCHAR(100) = 'Bankruptcy', -- Bankruptcy, PaymentChangeHistory
@schema VARCHAR(100) = 'DataMart_History'

SELECT Processing.partitionsCount(CONCAT('DataMart_History.',@DeltaTableName))

SELECT Processing.partitionsCount('DataMart_History.PaymentChangeHistory')

