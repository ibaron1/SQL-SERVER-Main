use master
go

select
session_id as spid, blocking_session_id as blocking_spid,
db_name(database_id) as dbName,
suser_name(user_id) as userName,
    (SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement,
start_time,status,command,
cpu_time,total_elapsed_time,
percent_complete,estimated_completion_time,reads,writes,logical_reads,
row_count,
lock_timeout,deadlock_priority,
granted_query_memory,
wait_type,wait_time,last_wait_type,wait_resource,open_transaction_count,open_resultset_count,text_size,
transaction_isolation_level,prev_error,nest_level,executing_managed_code
,query_plan 
from sys.dm_exec_requests AS s1 
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS s2
cross apply sys.dm_exec_query_plan(plan_handle) as s3  
WHERE s2.dbid is not null and db_name(s2.dbid) not in ('master','msdb') and session_id <> @@spid


/*
http://msdn.microsoft.com/en-us/library/ms177648.aspx
*/
