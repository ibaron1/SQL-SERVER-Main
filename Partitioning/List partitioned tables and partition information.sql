--ALL partitioned tables
select distinct t.name
from sys.partitions p
inner join sys.tables t
on p.object_id = t.object_id
where p.partition_number > 1

--returns all partitions
SELECT DISTINCT CONCAT(SCHEMA_NAME (T. schema_id), '. ' , T.name) AS tableName,
P.partition_number
FROM sys.partitions AS P
INNER JOIN sys. tables AS T
ON T.object_id = P.object_id
WHERE SCHEMA_NAME (T. schema_id) = 'DataMart_History'

--checks if table is partitioned - if not will return only partition = 1 ; for > 1 check will return empty result set
SELECT DISTINCT CONCAT (SCHEMA_NAME (T. schema_id) , ' . ' , T.name) AS tableName,
P.partition_number
FROM sys. partitions AS P
INNER JOIN sys. tables AS T
ON T.object_id = P.object_id
WHERE SCHEMA_NAME (T. schema_id) = 'DataMart_History'
AND T.name = 'PaymentChangeHistory'
AND P.partition_number > 1