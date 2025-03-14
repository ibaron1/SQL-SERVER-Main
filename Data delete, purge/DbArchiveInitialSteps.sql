if object_id('tfmarchive.DataArchiveInitialSteps') is not null
  drop proc tfmarchive.DataArchiveInitialSteps
go

/***************************************************************************************************************
Author. Eli Baron
Date created. 8-9-17
Purpose. Start new or restart current archiving cycle, is to be called from DataArchivingForAllWorkflows
****************************************************************************************************************/
create proc tfmarchive.DataArchiveInitialSteps
@AppDataType varchar(20),
@DataArchivingStarted datetime
as

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare @StartOfCurrentRun datetime = getdate()
declare @ArchiveAndPurgeArchivedOlderThan datetime

if exists (select 1 from tfmarchive.DbSpaceAfterArchiving where DbName = db_name()
  and AppDataType = @AppDataType and DataArchivingEnded is not null)
or not exists (select 1 from tfmarchive.DbSpaceAfterArchiving where DbName = db_name()
  and AppDataType = @AppDataType)
begin
	delete tfmarchive.DbSpaceAfterArchiving
	output deleted.* into tfmarchive.DbSpaceAfterArchiving_History
	where DbName = db_name() and AppDataType = @AppDataType

	insert tfmarchive.DbSpaceAfterArchiving
	(DbName,
	 DbSize_MB,
	 Orig_DbSpace_Used_MB ,
	 Orig_DbAvailable_Space_MB,
	 Orig_Percent_Used,
	 AppDataType,
	 DataArchivingStarted,
	 CurrentRunStarted)
	 select db_name() as DbName,
	 sum(cast(round(size/128.0, 0) as int)) as size_in_MB,
	 sum(cast(round(fileproperty(name, 'SpaceUsed')/128.0,0) as int)) as Space_used_in_MB,
	 sum(cast(round(size/128.0-(fileproperty(name, 'SpaceUsed')/128.0),0) as int)) as Available_Space_in_MB,
	 cast(cast(round(sum(cast(fileproperty(name, 'SpaceUsed')/128.0 as dec(10,2)))/sum(cast(size/128.0 as dec(10,2)))*100,0) as int) as varchar(10))+'%' as Percent_Used
	 ,@AppDataType
	 ,@DataArchivingStarted
	 ,@StartOfCurrentRun
	 from sys.database_files
		 where type_desc = 'rows'
	 group by type_desc
	 
	 -- truncate table for Archive ids

	 delete tfmarchive.DataArchivingLog
	 output deleted.* into tfmarchive.DataArchivingLog_History
	 where DbName = db_name() and AppDataType = @AppDataType

	 insert tfmarchive.DataArchivingLog(DbName,Tbl,AppDataType,workflowId,ifArchiveOnboarded)
	 select DbName,Tbl,AppDataType,workflowId,case when Retention_days is not null then 'Y' else 'N' end
	 from tfmarchive.DataArchivingCfg
	 where DbName = db_name() and AppDataType = @AppDataType

	 ;with LOB
	 as
	 (select (schema_name(o.schema_id)+'.'+o.name) as [Table],c.name as [column],
	 t.name as [Large datatype],c.length
	 from sys.objects o join sys.syscolumns c
	 on o.object_id = c.id and o.type = 'U'
	 join systypes t
	 on c.xtype = t.xtype and (t.name in ('image','text','xml') or (c.length = -1 and t.name <> 'sysname')))
	 update dal
	 set hasLOBcolumn = 'Y'
	 from tfmarchive.DataArchivingLog as dal 
	 join LOB 
	 on DbName = db_name() and dal.Tbl = LOB.[Table]
	 and AppDataType = @AppDataType
	 
	 update tfmarchive.DataArchivingLog
	 set hasLOBcolumn = 'Y'
	 where hasLOBcolumn is null
	 and DbName = db_name() and AppDataType = @AppDataType

	 --add timestamp to not active tables
	 update a
	 set ArchiveAndPurgeArchivedOlderThan = dateadd(dd,-1*(c.Retention_days),@DataArchivingStarted),ArchiveStartDate = @DataArchivingStarted
	 from tfmarchive.DataArchivingLog a join tfmarchive.DataArchivingCfg c
	 on c.DbName = a.DbName and c.Tbl = a.Tbl and c.AppDataType = a.AppDataType
	 where c.AppDataType = @AppDataType and a.ifArchiveOnboarded <> 'Y'

end
else
begin

	 --move data archiving from previous run into a history of archiving summary
	   insert tfmarchive.DbSpaceAfterArchiving_History
	   select * from tfmarchive.DbSpaceAfterArchiving
	   where DbName = db_name() and AppDataType = @AppDataType

	   --Move errors from previous run into the history log
	   insert tfmarchive.DataArchivingLog_History
	   select * from tfmarchive.DataArchivingLog
	   where ArchivingError is not null 

	   --Clear errors from from current log before the next run so it will log only its errors
	   update tfmarchive.DataArchivingLog
	   set ArchivingError = null
	   where ArchivingError is not null

	   select @DataArchivingStarted = DataArchivingStarted
	   from tfmarchive.DbSpaceAfterArchiving
	   where DbName = db_name() and AppDataType = @AppDataType

	   ;with cur_arch
	   as
	   (select sum(cast(round(size/128.0, 0) as int)) as size_in_MB,
		 sum(cast(round(fileproperty(name, 'SpaceUsed')/128.0,0) as int)) as Space_used_in_MB,
		 sum(cast(round(size/128.0-(fileproperty(name, 'SpaceUsed')/128.0),0) as int)) as Available_Space_in_MB,
		 cast(cast(round(sum(cast(fileproperty(name, 'SpaceUsed')/128.0 as dec(10,2)))/sum(cast(size/128.0 as dec(10,2)))*100,0) as int) as varchar(10))+'%' as Percent_Used
		 from sys.database_files
		 where type_desc = 'rows'
		 group by type_desc)
		update tfmarchive.DbSpaceAfterArchiving
		set Orig_DbSpace_Used_MB = Space_used_in_MB
		,Orig_DbAvailable_Space_MB = Available_Space_in_MB
		,Orig_Percent_Used = Percent_Used
		,CurrentRunStarted = @StartOfCurrentRun
		,CurentRunEnded = null
		,Updated_DbSpace_Used_MB = null
		,Updated_DbAvailable_Space_MB = null
		,Updated_Percent_Used = null
		from cur_arch
		where  DbName = db_name() and AppDataType = @AppDataType

end