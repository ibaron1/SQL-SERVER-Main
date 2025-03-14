SELECT distinct db_name()as DbName, o.name AS table_name, partition_number
FROM sys.partitions AS p 
    JOIN sys.objects AS o ON p.object_id = o.object_id
WHERE o.type ='U'
ORDER BY o.name