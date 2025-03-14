--past executions of the query
SELECT t.text,
     (qs.total_elapsed_time/1000) / qs.execution_count AS avg_elapsed_time,
     (qs.total_worker_time/1000) / qs.execution_count AS avg_cpu_time,
     ((qs.total_elapsed_time/1000) / qs.execution_count ) - ((qs.total_worker_time/1000) / qs.execution_count) AS avg_wait_time,
     qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
     qs.total_logical_writes / qs.execution_count AS avg_writes,
     (qs.total_elapsed_time/1000) AS cumulative_elapsed_time_all_executions
	 ,pl.query_plan
FROM sys.dm_exec_query_stats qs
     CROSS apply sys.Dm_exec_sql_text (qs.sql_handle) t
	 cross apply sys.dm_exec_query_plan(qs.sql_handle) as pl --in xml to see graphical
	 --cross apply sys.dm_exec_text_query_plan(qs.plan_handle, 0, -1) as pl -- as xml in text
--WHERE t.text like '<Your Query>%'
-- Replace <Your Query> with your query or the beginning part of your query. The special chars like '[','_','%','^' in the query should be escaped.
ORDER BY (qs.total_elapsed_time / qs.execution_count) DESC