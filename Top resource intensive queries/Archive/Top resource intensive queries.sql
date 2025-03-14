SELECT TOP(10) DB_NAME(t.[dbid]) AS [Database],
REPLACE(REPLACE(LEFT(t.[text], 255), CHAR(10),''), CHAR(13),'') AS [ShortQueryTXT], 
qs.total_logical_reads AS [TotalLogicalReads],
qs.min_logical_reads AS [MinLogicalReads],
qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.max_logical_reads AS [MaxLogicalReads],   
qs.min_worker_time AS [MinWorkerTime],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.max_worker_time AS [MaxWorkerTime], 
qs.min_elapsed_time AS [MinElapsedTime], 
qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime], 
qs.max_elapsed_time AS [MaxElapsedTime],
qs.execution_count AS [ExecutionCount], 
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%%' THEN 1 ELSE 0 END AS [HasMissingIX],
qs.creation_time AS [CreationTime]
,t.[text] AS [Complete Query Text], qp.query_plan AS [QueryPlan]
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
ORDER BY qs.total_logical_reads DESC OPTION (RECOMPILE)