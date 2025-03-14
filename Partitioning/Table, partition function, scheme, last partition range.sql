SELECT o.name as table_name,
pf.name as PartitionFunction,
ps.name as PartitionScheme,
MAX(rv. value) AS LastPartitionRange,
CASE WHEN MAX(rv.value) <= DATEADD(MONTH, 2, GETDATE()) THEN 1 else 0 END AS isRequiredMaintenance
-- INTO #temp
FROM sys.partitions p
INNER JOIN sys. indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
INNER JOIN sys.objects o ON p.object_id = o.object_id
INNER JOIN sys. system_internals_allocation_units au ON p.partition_id = au.container_id
INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
INNER JOIN sys.partition_functions pf ON pf.function_id = ps. function_id
INNER JOIN sys. partition_range_values rv ON pf. function_id = rv. function_id AND p.partition_number = rv.boundary_id
GROUP BY o.name, pf.name, ps.name