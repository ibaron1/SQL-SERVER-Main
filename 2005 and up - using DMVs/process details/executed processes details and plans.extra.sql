use master
go
SELECT db_name(s3.dbid) dbname, 
    last_execution_time, 
	s3.text,  
    (SELECT TOP 1 SUBSTRING(s3.text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),s3.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement,
    UseCounts,				--Number of times this cache object has been used since its inception
	size_in_bytes,			--Number of bytes consumed by the cache object    
    plan_generation_num,	--A sequence number that can be used to distinguish between instances of plans after a recompile
    creation_time as plan_compiled,
    execution_count,		--Number of times that the plan has been executed since it was last compiled
	CacheObjType, 
	ObjType,
    s4.query_plan,   
    total_worker_time,		--Total amount of CPU time, in microseconds, that was consumed by executions of this plan since it was compiled
    last_worker_time,		--CPU time, in microseconds, that was consumed the last time the plan was executed 
    min_worker_time,		--Minimum CPU time, in microseconds, that this plan has ever consumed during a single execution 
    max_worker_time,		--Maximum CPU time, in microseconds, that this plan has ever consumed during a single execution
    total_physical_reads,	--Total number of physical reads performed by executions of this plan since it was compiled
    last_physical_reads,	--Number of physical reads performed the last time the plan was execut
    min_physical_reads,		--Minimum number of physical reads that this plan has ever performed during a single execution 
    max_physical_reads,		--Maximum number of physical reads that this plan has ever performed during a single execution  
    total_logical_writes,	--Total number of logical writes performed by executions of this plan since it was compiled 
    last_logical_writes,	--Number of logical writes performed the last time the plan was executed 
    min_logical_writes,		--Minimum number of logical writes that this plan has ever performed during a single execution 
    max_logical_writes		--Maximum number of logical writes that this plan has ever performed during a single execution  
FROM sys.dm_exec_query_stats AS s1 
join sys.dm_exec_cached_plans as s2
on s1.plan_handle = s2.plan_handle
outer apply sys.dm_exec_sql_text(s1.plan_handle) as s3
outer apply sys.dm_exec_query_plan(s1.plan_handle) as s4  
WHERE s3.dbid is not null and db_name(s3.dbid) not in ('msdb')
and text not like '%sys%'and cacheobjtype ='compiled plan' 
--ORDER BY s1.sql_handle, s1.statement_start_offset, s1.statement_end_offset;
order by db_name(s3.dbid), last_execution_time desc