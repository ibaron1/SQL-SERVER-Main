SELECT o.name AS table_name, au.type_desc AS allocation_type, au.data_pages, p.rows, partition_number
FROM sys.allocation_units AS au
    JOIN sys.partitions AS p ON au.container_id = p.partition_id
    JOIN sys.objects AS o ON p.object_id = o.object_id
    JOIN sys.indexes AS i ON p.index_id = i.index_id AND i.object_id = p.object_id
WHERE o.name = N'srf_main.BCPValAgg' 
ORDER BY o.name, p.index_id

-- without allocation info
SELECT distinct db_name(), o.name AS table_name, p.rows, partition_number
FROM sys.partitions AS p 
    JOIN sys.objects AS o ON p.object_id = o.object_id
    JOIN sys.indexes AS i ON p.index_id = i.index_id AND i.object_id = p.object_id
--WHERE o.type ='U' and lower(o.name) like '%log%'
where partition_number > 1 
ORDER BY o.name

SELECT distinct db_name()as DbName, o.name AS table_name, partition_number
FROM sys.partitions AS p 
    JOIN sys.objects AS o ON p.object_id = o.object_id
WHERE o.type ='U' and partition_number > 1
ORDER BY o.name

-- from all dbs
EXEC sp_MSforeachdb 'USE [?] IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'', "ReportServer", "ReportServerTempDB")
SELECT distinct ''?'' as DbName, o.name AS table_name, p.rows, partition_number
FROM sys.partitions AS p 
    JOIN sys.objects AS o ON p.object_id = o.object_id
    JOIN sys.indexes AS i ON p.index_id = i.index_id AND i.object_id = p.object_id
WHERE o.type =''U'' and lower(o.name) like ''%log%'' 




