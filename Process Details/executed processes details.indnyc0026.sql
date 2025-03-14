use master
go
SELECT db_name(s2.dbid) dbname,
    convert(varchar(400), '') as ObjectName,
    convert(varchar(40) ,'') as ObjType,
    s3.objectid,  
    --s2.text, 
    (SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement,
    last_execution_time,
    last_elapsed_time as last_elapsed_time_in_microseconds,
    max_elapsed_time, 
    min_elapsed_time,   
    execution_count,		--Number of times that the plan has been executed since it was last compiled
    UseCounts,				--Number of times this cache object has been used since its inception
	size_in_bytes,			--Number of bytes consumed by the cache object    
    plan_generation_num,	--A sequence number that can be used to distinguish between instances of plans after a recompile.
    creation_time as plan_compiled_time,   
    last_physical_reads,
    total_physical_reads,  
    min_physical_reads,  
    max_physical_reads,  
    total_logical_writes, 
    last_logical_writes, 
    min_logical_writes, 
    max_logical_writes
	,s3.query_plan 
into #tmp  
FROM sys.dm_exec_query_stats AS s1
join sys.dm_exec_cached_plans as p
on s1.plan_handle = p.plan_handle 
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS s2
cross apply sys.dm_exec_text_query_plan(s1.plan_handle,statement_start_offset,statement_end_offset) as s3  
WHERE s2.dbid is not null and db_name(s2.dbid) not in ('msdb')
go

use RightFax
go

update #tmp
set 
ObjectName = name,
ObjType = case type 
when 'P' then 'proc'
when 'TR' then 'trigger'
when 'TF' then 'table function'
when 'V' then 'view'
when 'IF' then 'In-lined table-function'
when 'FN' then 'Scalar function'
when 'D' then 'default'
when 'L' then 'Log'  
when 'K' then 'PRIMARY KEY or UNIQUE constraint'
when 'F' then 'FOREIGN KEY constraint'
end 
from sysobjects
where id = objectid
go

-- Detailed stats
select * from #tmp
--where dbname = 'riskbook' -- riskworld	riskbook
--and ObjectName = 'GetProxiedCurveIDsWithPositions'
where ObjType in ('proc','trigger')
order by dbname,last_execution_time desc, last_elapsed_time_in_microseconds desc, execution_count -- by latest execution
--order by last_elapsed_time_in_microseconds desc, last_execution_time, execution_count -- by CPU 
--order by last_physical_reads desc, last_execution_time, execution_count -- by physical IO
--order by last_logical_writes desc, last_execution_time, execution_count -- by logical IO

--Summarized stats

select dbname, ObjectName, ObjType, sum(execution_count) as total_execution_count
into #tmp1
from #tmp
where ObjType in ('proc','trigger')
group by dbname, ObjectName, ObjType

select * from #tmp1
order by dbname,total_execution_count desc

drop table #tmp, #tmp1
go
