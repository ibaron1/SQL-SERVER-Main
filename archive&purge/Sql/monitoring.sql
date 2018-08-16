--Monitor the Data Archiving cycle

select * from [core].[ArchivingDataProcessing] -- detailed control log table for data archiving

select * from core.ExpiredArchivedDataProcessing -- detailed control log table for archived data purging

--Bird view
select * from [core].[ControlOfDataArchiving]

select * from [core].[DataArchivingAndPurgingConfig]

--Zoom into archiving
select DbName,workflowId,Tbl, 
ArchiveOlderThan,RowsToArchive,RowsArchived,StartDate,LastDate,getdate() as CurrentDate,
case when RowsToArchive > 0 then datediff(ss,StartDate,coalesce(LastDate,getdate())) end as RunTime_sec, 
cast(1.0*RowsArchived/case datediff(ss,StartDate,coalesce(LastDate,getdate())) when 0 then 1 else datediff(ss,StartDate,coalesce(LastDate,getdate())) end as int)  as [Rows archived per sec],
EndDate,Error
from [core].[ArchivingDataProcessing]
order by LastDate desc -- use this if archiving is progressing
--order by StartDate desc -- use this is archiving got stuck

select * from [core].[ArchivingDataProcessing] 

select @@servername as sql_server, dbname, getdate() as [Time now], DataArchivingStarted,CurrentRunStarted,CurentRunEnded,DataArchivingEnded 
from [core].[ControlOfDataArchiving]

--sp_spaceused '[core].[loadIdsForDataArchiving]' --118,473              

select @@servername as sql_server, dbname, getdate() as [Time now], DataArchivingStarted,CurrentRunStarted,CurentRunEnded,DataArchivingEnded 
from [core].[ControlOfDataArchiving]
      

--Speed of archiving
select DbName,workflowId,Tbl, 
ArchiveOlderThan,RowsToArchive,RowsArchived,StartDate,LastDate,getdate() as CurrentDate,
case when RowsToArchive > 0 then datediff(ss,StartDate,coalesce(LastDate,getdate())) end as RunTime_sec, 
cast(1.0*RowsArchived/case datediff(ss,StartDate,coalesce(LastDate,getdate())) when 0 then 1 else datediff(ss,StartDate,coalesce(LastDate,getdate())) end as int)  as [Rows archived per sec],
EndDate,Error
from [core].[ArchivingDataProcessing]
order by LastDate desc -- use this if archiving is progressing
--order by StartDate desc -- use this is archiving got stuck



--Speed of archiving specific table
select DbName,workflowId,Tbl, 
ArchiveOlderThan,RowsToArchive,RowsArchived,StartDate,LastDate,EndDate,
case when RowsToArchive > 0 then datediff(ss,StartDate,coalesce(LastDate,getdate())) end as RunTime_sec, 
cast(1.0*RowsArchived/case datediff(ss,StartDate,coalesce(LastDate,getdate())) when 0 then 1 else datediff(ss,StartDate,coalesce(LastDate,getdate())) end as int)  as [Rows archived per sec],
Error
from [core].[ArchivingDataProcessing]
where tbl = 'Step' and RowsArchived is not null
order by RowsArchived desc

select * from [core].[ArchivingDataProcessing_History] --2018-03-02 18:19:24.153
where cast(StartDate as date) = '2018-03-02'
order by RowsArchived desc

select * from [core].[ArchivingDataProcessing]
where Error is not null

select * from [core].[ArchivingDataProcessing]
where workflowid = 576

select * from TFM_Archive.[core].[DataArchivingAndPurgingConfig]
where DbName = 'TFM' and AppDataType = 'tfm'
and workflowid = 576

/********** add workflow to archiving if is missing *****/

insert core.ArchivingDataProcessing(DbName,Tbl,AppDataType,workflowId,ifArchiveOnboarded)
	 select DbName,Tbl,AppDataType,workflowId,case when RetentionDays is not null then 'Y' else 'N' end
	 from core.DataArchivingAndPurgingConfig
	 where DbName = 'TFM' and AppDataType = 'tfm'
	 and isnull(workflowid,0) not in (select isnull(workflowid,0) from core.ArchivingDataProcessing)


/*
truncate table [core].ControlOfDataArchiving
truncate table [core].ControlOfDataArchiving_History
truncate table [core].ArchivingDataProcessing
truncate table [core].ArchivingDataProcessing_History
*/

--Purge of expired archived data
select * from core.ControlPurgeOfExpiredArchivedData
/*
truncate table core.ControlPurgeOfExpiredArchivedData
truncate table core.ControlPurgeOfExpiredArchivedData_History
*/

select * from core.ExpiredArchivedDataProcessing
where error is not null
/*
truncate table core.ExpiredArchivedDataProcessing
truncate table core.ExpiredArchivedDataProcessing_History
*/