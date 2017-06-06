SELECT db_name(database_id),object_name(object_id),*
FROM sys.dm_db_missing_index_details
order by 1
 
 
SELECT TOP 20 *
into #t
FROM sys.dm_db_missing_index_group_stats
ORDER BY avg_total_user_cost * avg_user_impact * (user_seeks + user_scans) DESC;
 
SELECT db_name(database_id) as dbname, object_name(object_id)as [table], migs.group_handle, mid.*, 
#t.avg_total_user_cost, #t.avg_user_impact, #t.user_seeks, #t.user_scans
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON (migs.group_handle = mig.index_group_handle)
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON (mig.index_handle = mid.index_handle)
join #t on migs.group_handle = #t.group_handle
and db_name(database_id) not in ('master','msdb')
order by 1
 
drop table #t
 
 
/*********************************/

SELECT TOP 20 *
into #t
FROM sys.dm_db_missing_index_group_stats
ORDER BY avg_total_user_cost * avg_user_impact * (user_seeks + user_scans) DESC;
 
SELECT db_name(database_id) as dbname, migs.group_handle, mid.*, 
#t.avg_total_user_cost, #t.avg_user_impact, #t.user_seeks, #t.user_scans
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON (migs.group_handle = mig.index_group_handle)
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON (mig.index_handle = mid.index_handle)
join #t on migs.group_handle = #t.group_handle
where db_name(database_id) = 'riskbook'
order by statement
 
drop table #t
 
/********
sys.dm_db_missing_index_columns (Transact-SQL)
sys.dm_db_missing_index_details (Transact-SQL)
sys.dm_db_missing_index_groups (Transact-SQL)
*********/
 
