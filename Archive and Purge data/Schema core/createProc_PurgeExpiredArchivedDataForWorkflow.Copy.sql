use TFM_Archive
go
if object_id('core.PurgeExpiredArchivedDataForWorkflow') is not null
  drop proc core.PurgeExpiredArchivedDataForWorkflow
go
/***********************************************************************************************************************************
Author. Eli Baron
Date created. 8-10-17
Purpose. purge expired archived workflow's data 

Date modified. 8-29-17 by Eli Baron
 Proc was moved to core schema
 Added tables from tfmload schema for data archiving

Date modified. 10-23-17 by Eli Baron
As database schema changed the data archiving and purging (dA&P) must be synchronized with that changes:
-	Tables in schema tfmload no longer exist as there is no staging to process log files
-	Tables tfm.RequestPayloadSummary, tfm.RequestLoad were removed
-	Table Error is used only in stored procedure usp_GetErrorInfo, and it is no longer used so Error must be removed from dA&P
-	New tables LoggerError, LoadErrorHistory, FileLoadHistory added to dA&P

Replaced temp tables with table variables

Date modified. 1-22-18 by Eli Baron, Jira WMTRTFMSVC-126
	Tables FileLoad, LoggerError, LoadError were added for Data Archiving

Modified by Eli Baron on 1-30-18
to move data archiving of tables FileLoad, LoggerError, LoadError into SP core.PurgeExpiredDataAcrossWorkflows

Modified by Eli Baron on 3-21-2018
Purpose. Step table was removed, code change to incorporate new columns and transactioWMTRTFMSVC-226

Modified by Eli Baron on 6-7-2018
Purpose. Remove use of table variables since they get emptied for large volume, Jira WMTRTFMSVC-319
***********************************************************************************************************************************/
create proc core.PurgeExpiredArchivedDataForWorkflow
@RunTime_min int,
@AppDataType varchar(20),
@workflowId int,
@StartOfCurrentRun datetime,
@EndOfCurrentRun char(1) output
as

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare @ArchivingBatchSize int, 
@PurgeExpiredDataOlderThan datetime,
@tbl varchar(128),
@rc int

declare @Id int,@maxId int

-- purge expired data 
select @PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),ctrl.DataPurgeStarted),101)
from core.DataArchivingAndPurgingConfig as cfg
cross join core.ControlPurgeOfExpiredArchivedData as ctrl
where cfg.AppDataType = @AppDataType and Tbl = 'FileLoad'

insert  core.transactionIdPurging
select transactionId -- for RequestKeyAttributes
from tfm.Request
where workflowId = @workflowId and loadId in (select loadId from core.loadIdsForDataPurging)

insert core.activityIdPurging
select activityId -- for Payload and RequestLoad 
from tfm.Activity
where transactionId in (select transactionId from core.transactionIdPurging)

--1. 
set @tbl = 'RequestKeyAttributes'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin

	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.RequestKeyAttributes --with (forceseek) 
	    where transactionId in (select transactionId from  core.transactionIdPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and StartDate is null
	option (maxdop 0)

	if (select RowsToPurge from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	select @Id = min(transactionId), @maxId = max(transactionId) from core.transactionIdPurging

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
		end

		delete r
		from tfm.RequestKeyAttributes as r 
		join core.transactionIdPurging as Id
		on r.transactionId = Id.transactionId
		where Id.transactionId >= @Id and Id.transactionId < @Id + @ArchivingBatchSize 

		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update core.ExpiredArchivedDataProcessing
	set Error = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()
    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--2. 
set @tbl = 'Payload'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
		(select count(1) from tfm.Payload 
	     where activityId in (select activityId from core.activityIdPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and StartDate is null
    
	if (select RowsToPurge from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	select @Id = min(activityId), @maxId = max(activityId) from core.activityIdPurging

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
		end

		delete p
		from tfm.Payload as p --with (forceseek)
		join core.activityIdPurging as Id
		on p.activityId = Id.activityId
		where Id.activityId >= @Id and Id.activityId < @Id + @ArchivingBatchSize 
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update core.ExpiredArchivedDataProcessing
	set Error = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()
    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--3. 
set @tbl = 'Activity'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.Activity 
	    where activityId in (select activityId from core.activityIdPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and StartDate is null
    

	if (select RowsToPurge from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	select @Id = min(activityId), @maxId = max(activityId) from core.activityIdPurging

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
		end

		delete a
		from tfm.Activity as a --with (forceseek)
		join core.activityIdPurging as Id
		on a.activityId = Id.activityId
		where Id.activityId >= @Id and Id.activityId < @Id + @ArchivingBatchSize 
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update core.ExpiredArchivedDataProcessing
	set Error = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()
    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--4. 
set @tbl = 'Request'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.Request 
	    where transactionId in (select transactionId from core.transactionIdPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and StartDate is null
    
	if (select RowsToPurge from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	select @Id = min(transactionId), @maxId = max(transactionId) from core.transactionIdPurging

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
		end

		delete r
		from tfm.Request as r --with (forceseek)
		join core.transactionIdPurging as Id
		on r.transactionId = Id.transactionId
		where Id.transactionId >= @Id and Id.transactionId < @Id + @ArchivingBatchSize 
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update core.ExpiredArchivedDataProcessing
	set Error = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()
    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

EndOfCurrentRun:

GO