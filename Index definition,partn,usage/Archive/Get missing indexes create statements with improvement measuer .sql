SELECT tableName,create_index_statement,improvement_measure,user_seeks,CONVERT (varchar(30), last_user_seek, 126) AS last_user_seek,user_scans,avg_user_impact,avg_user_impact,CAST(avg_total_user_cost AS DEC(28,2)) AS avg_total_user_cost,runtime
FROM  
(   SELECT  TOP (2147483647) 
  CONVERT (varchar(30), getdate(), 126) AS runtime,  mig.index_group_handle,  mid.index_handle,
  CONVERT (decimal (28, 1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) ) AS improvement_measure,
  CONCAT(QUOTENAME(OBJECT_SCHEMA_NAME(mid.object_id)), '.', QUOTENAME(OBJECT_NAME(mid.object_id))) AS tableName,
  'CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle) + ' ON ' + mid.statement + ' (' + ISNULL (mid.equality_columns, '') + CASE
    WHEN mid.equality_columns IS NOT NULL
    AND mid.inequality_columns IS NOT NULL THEN ','
    ELSE ''
  END + ISNULL (mid.inequality_columns, '') + ')' + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
  migs.*, mid.database_id, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
	INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
	INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()
AND CONVERT (decimal (28, 1),migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC) AS SYSDATA
--WHERE tableName = '[Results].[RuleResults]'
ORDER BY tableName, user_seeks DESC, improvement_measure DESC
