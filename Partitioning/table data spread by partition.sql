DROP table IF EXISTS #t;

SELECT DISTINCT CONCAT(SCHEMA_NAME(o.schema_id),'.',o.name) as table_name, rv.value as partition_range, fg.name as file_groupName,
p.partition_number, p.rows as number_of_rows
INTO #t
FROM sys.partitions p
INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
INNER JOIN sys.objects o ON p.object_id = o.object_id
INNER JOIN sys. system_internals_allocation_units au ON p.partition_id = au.container_id
INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id
INNER JOIN sys. destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number
INNER JOIN sys. filegroups fg ON dds.data_space_id = fg.data_space_id
LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv. function_id AND p.partition_number = rv.boundary_id
WHERE o.object_id = OBJECT_ID('DataMart_History. Loan' ) AND p.rows > 0;
-- WHERE SCHEMA_NAME(o.schema_id) = 'DataMart_History'
-- ORDER BY number_of_rows desc

SELECT table_name, number_of_rows, partition_number
FROM #t
WHERE number_of_rows <> 0
ORDER BY table_name, number_of_rows, partition_number DESC

SELECT table_name, number_of_rows, partition_number, udh. RunTime AS [update run time]
FROM #t AS t
JOIN DataMart_Log. Update_DataMart_History_log AS udh
ON REPLACE(udh. ProcedureName,'Processing. Update_DataMart_History_','') = REPLACE(table_name, 'DataMart_History. ' ,' ')
WHERE number_of_rows <> 0 AND partition_number = 1
AND NOT EXISTS
(SELECT '1' FROM #t WHERE table_name = t.table_name AND partition_number <> 1 AND number_of_rows > 0)
ORDER BY number_of_rows DESC