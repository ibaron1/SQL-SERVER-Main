--DECLARE @schema VARCHAR(100) = NULL
DECLARE @schema VARCHAR(100) = 'DataMart' 

SELECT CONCAT(SCHEMA_NAME(t.schema_id),'.',t.NAME) AS TableName,  
    i.name as indexName,
    FORMAT(p.[Rows],'N0') AS [Rows],
    FORMAT(sum(a.total_pages),'N0') as TotalPages, 
    FORMAT(sum(a.used_pages),'N0') as UsedPages, 
    FORMAT(sum(a.data_pages),'N0') as DataPages,
    isnull((select sum(a1.total_pages)
     from sys.indexes i1 
		INNER JOIN 
     sys.partitions p1
     on i1.object_id = p1.OBJECT_ID AND i1.index_id = p1.index_id 
		INNER JOIN 
    sys.allocation_units a1 ON p1.partition_id = a1.container_id
    where i.object_id = p1.OBJECT_ID AND i.index_id = p1.index_id
    and a1.type = 2
    group by i1.object_id
    ), 0) as TotalLOBpages,
    (sum(a.total_pages) * 8) / 1024 as TotalSpaceMB, 
    (sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, 
    (sum(a.data_pages) * 8) / 1024 as DataSpaceMB
FROM 
    sys.tables t
INNER JOIN  	
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    t.NAME NOT LIKE 'dt%' AND
	SCHEMA_NAME(t.schema_id) = ISNULL(@schema, SCHEMA_NAME(t.schema_id)) AND
    i.OBJECT_ID > 255 AND 	
    i.index_id <= 1
GROUP BY 
    t.schema_id,t.NAME, i.object_id, i.index_id, i.name, p.[Rows]
ORDER BY 
    SCHEMA_NAME(t.schema_id),OBJECT_NAME(i.object_id)