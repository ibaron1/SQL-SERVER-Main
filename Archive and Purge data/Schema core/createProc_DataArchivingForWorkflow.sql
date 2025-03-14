USE [TFM_Archive]
GO
/****** Object:  StoredProcedure [core].[DataArchivingForWorkflow]    Script Date: 4/10/2018 2:01:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************************************************************
Author. Eli Baron
Date created. 8-10-17
Purpose. archive data for a workflow

Date modified. 8-29-17 by Eli Baron
 Moved to core schema
 Added tables from tfmload schema for data archiving

Date modified. 10-23-17 by Eli Baron
As database schema changed the data archiving and purging (dA&P) must be synchronized with that changes:
-	Tables in schema tfmload no longer exist as there is no staging to process log files
-	Tables tfm.RequestPayloadSummary, tfm.RequestLoad were removed
-	Table Error is used only in stored procedure usp_GetErrorInfo, and it is no longer used so Error must be removed from dA&P
-	New tables LoggerError, LoadErrorHistory, FileLoadHistory added to dA&P

Replaced temp tables with table variables

Date modified. 1-19-18 by Eli Baron, Jira WMTRTFMSVC-126
	Tables FileLoad, LoggerError, LoadError were added for Data Archiving

Modified by Eli Baron on 1-30-18
to move data archiving of tables FileLoad, LoggerError, LoadError into SP core.DataArchivingAcrossWorkflows

Modified by Eli Baron on 3-7-18
Code changes to address change in cardinality estimator in version SQLSVR 2014, Jira WMTRTFMSVC-204) 

Modified by Eli Baron on 3-21-2018
Purpose. Step table was removed, code change to incorporate new columns and transactioWMTRTFMSVC-226

Modified by Eli Baron on 3-28-18
Created permanent tables to hold target ids to replace temp tables or table variables.
delete with option to insert deleted rows from TFM to TFM_Archive database was replaced by insert followed by delete,
delete does not use top but batch of target ids from min to max
******************************************************************************************************************************/
ALTER proc [core].[DataArchivingForWorkflow]
@RunTime_min int,
@AppDataType varchar(20),
@workflowId int,
@StartOfCurrentRun datetime,
@EndOfCurrentRun char(1) output
with recompile
as

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare @ArchivingBatchSize int, 
@ArchiveOlderThan datetime,
@tbl varchar(128),
@rc int

declare @Id int,@maxId int

select @ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),ctrl.DataArchivingStarted),101)
from core.DataArchivingAndPurgingConfig as cfg
cross join core.ControlOfDataArchiving as ctrl
where cfg.AppDataType = @AppDataType and Tbl = 'FileLoad'

insert  core.transactionIdArchiving
select transactionId 
from TFM.tfm.Request
where workflowId = @workflowId and loadId in (select loadId from core.loadIdsForDataArchiving)

insert core.activityIdArchiving
select activityId 
from TFM.tfm.Activity
where transactionId in (select transactionId from core.transactionIdArchiving)

--1. 
set @tbl = 'RequestKeyAttributes'

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin

	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.RequestKeyAttributes --with (forceseek) 
	    where transactionId in (select transactionId from  core.transactionIdArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and StartDate is null

	if (select RowsToArchive from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	select @Id = min(transactionId), @maxId = max(transactionId) from core.transactionIdArchiving

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
		end

		insert into tfm.RequestKeyAttributes
		select r.* from TFM.tfm.RequestKeyAttributes as r --with (forceseek)
		join core.transactionIdArchiving as Id
		on r.transactionId = Id.transactionId
		where Id.transactionId >= @Id and Id.transactionId < @Id + @ArchivingBatchSize 
		and not exists
		(select '1' from tfm.RequestKeyAttributes
		 where keyName = r.keyName and keyValue = r.keyValue and transactionId = r.transactionId)

		delete r
		from TFM.tfm.RequestKeyAttributes as r --with (forceseek)
		join core.transactionIdArchiving as Id
		on r.transactionId = Id.transactionId
		where Id.transactionId >= @Id and Id.transactionId < @Id + @ArchivingBatchSize 

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update core.ArchivingDataProcessing
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
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
		(select count(1) from TFM.tfm.Payload 
	     where activityId in (select activityId from core.activityIdArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and StartDate is null
    
	if (select RowsToArchive from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	select @Id = min(activityId), @maxId = max(activityId) from core.activityIdArchiving

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
		end

		insert into tfm.Payload
		select p.* from TFM.tfm.Payload as p --with (forceseek)
		join core.activityIdArchiving as Id
		on p.activityId = Id.activityId
		where Id.activityId >= @Id and Id.activityId < @Id + @ArchivingBatchSize 
		and not exists
		(select '1' from tfm.Payload
		 where activityId = p.activityId)		

		delete p
		from TFM.tfm.Payload as p --with (forceseek)
		join core.activityIdArchiving as Id
		on p.activityId = Id.activityId
		where Id.activityId >= @Id and Id.activityId < @Id + @ArchivingBatchSize 
		
		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update core.ArchivingDataProcessing
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
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.Activity 
	    where activityId in (select activityId from core.activityIdArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and StartDate is null
    

	if (select RowsToArchive from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	select @Id = min(activityId), @maxId = max(activityId) from core.activityIdArchiving

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
		end

		insert into tfm.Activity
		select a.* from TFM.tfm.Activity as a --with (forceseek)
		join core.activityIdArchiving as Id
		on a.activityId = Id.activityId
		where Id.activityId >= @Id and Id.activityId < @Id + @ArchivingBatchSize 
		and not exists
		(select '1' from tfm.Activity
		 where activityId = a.activityId)	

		delete a
		from TFM.tfm.Activity as a --with (forceseek)
		join core.activityIdArchiving as Id
		on a.activityId = Id.activityId
		where Id.activityId >= @Id and Id.activityId < @Id + @ArchivingBatchSize 
		
		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update core.ArchivingDataProcessing
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
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.Request 
	    where transactionId in (select transactionId from  core.transactionIdArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and StartDate is null
    

	if (select RowsToArchive from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	select @Id = min(transactionId), @maxId = max(transactionId) from core.transactionIdArchiving

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
		end

		insert into tfm.Request
		select r.* from TFM.tfm.Request as r --with (forceseek)
		join core.transactionIdArchiving as Id
		on r.transactionId = Id.transactionId
		where Id.transactionId >= @Id and Id.transactionId < @Id + @ArchivingBatchSize 
		and not exists
		(select '1' from tfm.Request
		 where transactionId = r.transactionId)

		delete r
		from TFM.tfm.Request as r --with (forceseek)
		join core.transactionIdArchiving as Id
		on r.transactionId = Id.transactionId
		where Id.transactionId >= @Id and Id.transactionId < @Id + @ArchivingBatchSize 
		
		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update core.ArchivingDataProcessing
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

