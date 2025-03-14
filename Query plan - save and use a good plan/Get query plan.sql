SELECT UseCounts, Cacheobjtype, Objtype, TEXT, queryplan.query_plan, DB_NAME(queryplan.dbid) , OBJECT_NAME(queryplan.objectid) , queryplan.objectid
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) sqltext
CROSS APPLY sys.dm_exec_query_plan(plan_handle) queryplan
WHERE OBJECT_NAME (queryplan.objectid) = 921822396
-- queryplan.objectid = 603201249 -- 921822396

drop table if exists #a;
create TABLE #a
(ProcedureName varchar(200), objectid int, sqltext varchar(MAX), query_plan XML)

INSERT #a
SELECT Hlog.ProcedureName, queryplan.objectid, sqltext.TEXT, queryplan.query_plan
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) sqltext
CROSS APPLY sys.dm_exec_query_plan(plan_handle) queryplan
CROSS APPLY DataMart_Log.Update_DataMart_MonthEndHistory_log AS Hlog
WHERE queryplan.dbid = DB_ID() AND queryplan.objectid = OBJECT_ID(ProcedureName)

SELECT * FROM #a

