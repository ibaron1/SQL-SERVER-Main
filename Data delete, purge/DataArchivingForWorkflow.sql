use TFM
go

if object_id('tfmarchive.DataArchivingForWorkflow') is not null
  drop proc tfmarchive.DataArchivingForWorkflow
go

/***************************************************************************************************************
Author. Eli Baron
Date created. 8-10-17
Purpose. SP to archive data for a workflow
****************************************************************************************************************/
create proc tfmarchive.DataArchivingForWorkflow
@RunTime_min int,
@AppDataType varchar(20),
@workflowId int,
@StartOfCurrentRun datetime,
@EndOfCurrentRun char(1) output
as

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare @ArchiveBatchSize int, 
@ArchiveAndPurgeArchivedOlderThan datetime,
@PurgeArchivedDataOlderThan datetime,
@tbl varchar(128),
@rc int

-- archive data
select @ArchiveAndPurgeArchivedOlderThan = convert(char(10), dateadd(dd,-1*(Retention_days),@StartOfCurrentRun),101)
from tfmarchive.DataArchivingCfg
where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = 'tfmarchive.Request'

select transactionId into #transactionId -- for RequestKeyAttributes, Step
from tfmarchive.Request
where workflowId = @workflowId and timestamp < @ArchiveAndPurgeArchivedOlderThan

select tranStepId into #tranStepId -- for Activity
from tfmarchive.Step
where transactionId in (select transactionId from #transactionId)

select activityId into #activityId -- for Payload
from tfmarchive.Activity
where tranStepId in (select tranStepId from #tranStepId)

-- remove expired archived data 

--1. 
set @tbl = 'tfmarchive.RequestKeyAttributes'

begin try
while exists
(select 1 from tfmarchive.DataArchivingLog
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from tfmarchive.DataArchivingCfg
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and Retention_days is not null)
 and ArchiveEndDate is null)
 begin

	update tfmarchive.DataArchivingLog
	set ArchiveAndPurgeArchivedOlderThan = @ArchiveAndPurgeArchivedOlderThan
	   ,RowsToArchive = 
	   (select count(1) from tfmarchive.RequestKeyAttributes 
	    where transactionId in (select transactionId from #transactionId))
	   ,ArchiveStartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and ArchiveStartDate is null
    option (maxdop 0)

	if (select RowsToArchive from tfmarchive.DataArchivingLog 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select @ArchiveAndPurgeArchivedOlderThan = convert(char(10), dateadd(dd,-1*(Retention_days),@StartOfCurrentRun),101)
	      ,@ArchiveBatchSize = ArchiveBatchSize
	from tfmarchive.DataArchivingCfg
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @rc = @ArchiveBatchSize

	while @rc = @ArchiveBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchiveBatchSize) from tfmarchive.RequestKeyAttributes
		output deleted.* into TFM_Archive.tfmarchive.RequestKeyAttributes
		where transactionId in (select transactionId from #transactionId)
		option (maxdop 0)

		set @rc = @@rowcount

		update tfmarchive.DataArchivingLog
		set ArchivedRows = isnull(ArchivedRows, 0) + @rc
		,LastArchiveDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	end
	
	update tfmarchive.DataArchivingLog
	set ArchiveEndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update tfmarchive.DataArchivingLog
	set ArchivingError = 
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
set @tbl = 'tfmarchive.Payload'

begin try
while exists
(select 1 from tfmarchive.DataArchivingLog
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from tfmarchive.DataArchivingCfg
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and Retention_days is not null)
 and ArchiveEndDate is null)
 begin 
	update tfmarchive.DataArchivingLog
	set ArchiveAndPurgeArchivedOlderThan = @ArchiveAndPurgeArchivedOlderThan
	   ,RowsToArchive = 
	   (select count(1) from tfmarchive.Payload 
	    where activityId in (select activityId from #activityId)
		   or transactionId in (select transactionId from #transactionId))
	   ,ArchiveStartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and ArchiveStartDate is null
    option (maxdop 0)

	if (select RowsToArchive from tfmarchive.DataArchivingLog 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select @ArchiveAndPurgeArchivedOlderThan = convert(char(10), dateadd(dd,-1*(Retention_days),@StartOfCurrentRun),101)
	      ,@ArchiveBatchSize = ArchiveBatchSize
	from tfmarchive.DataArchivingCfg
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @rc = @ArchiveBatchSize

	while @rc = @ArchiveBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchiveBatchSize) from tfmarchive.Payload
		output deleted.* into TFM_Archive.tfmarchive.Payload
		where activityId in (select activityId from #activityId)
		   or transactionId in (select transactionId from #transactionId)
		option (maxdop 0)

		set @rc = @@rowcount

		update tfmarchive.DataArchivingLog
		set ArchivedRows = isnull(ArchivedRows, 0) + @rc
		,LastArchiveDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	end
	
	update tfmarchive.DataArchivingLog
	set ArchiveEndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update tfmarchive.DataArchivingLog
	set ArchivingError = 
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
set @tbl = 'tfmarchive.Activity'

begin try
while exists
(select 1 from tfmarchive.DataArchivingLog
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from tfmarchive.DataArchivingCfg
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and Retention_days is not null)
 and ArchiveEndDate is null)
 begin 
	update tfmarchive.DataArchivingLog
	set ArchiveAndPurgeArchivedOlderThan = @ArchiveAndPurgeArchivedOlderThan
	   ,RowsToArchive = 
	   (select count(1) from tfmarchive.Activity 
	    where activityId in (select activityId from #activityId))
	   ,ArchiveStartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and ArchiveStartDate is null
    option (maxdop 0)

	if (select RowsToArchive from tfmarchive.DataArchivingLog 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select @ArchiveAndPurgeArchivedOlderThan = convert(char(10), dateadd(dd,-1*(Retention_days),@StartOfCurrentRun),101)
	      ,@ArchiveBatchSize = ArchiveBatchSize
	from tfmarchive.DataArchivingCfg
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @rc = @ArchiveBatchSize

	while @rc = @ArchiveBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchiveBatchSize) from tfmarchive.Activity
		output deleted.* into TFM_Archive.tfmarchive.Activity
		where activityId in (select activityId from #activityId)
		option (maxdop 0)

		set @rc = @@rowcount

		update tfmarchive.DataArchivingLog
		set ArchivedRows = isnull(ArchivedRows, 0) + @rc		
		,LastArchiveDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	end
	
	update tfmarchive.DataArchivingLog
	set ArchiveEndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update tfmarchive.DataArchivingLog
	set ArchivingError = 
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
set @tbl = 'tfmarchive.Step'

begin try
while exists
(select 1 from tfmarchive.DataArchivingLog
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from tfmarchive.DataArchivingCfg
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and Retention_days is not null)
 and ArchiveEndDate is null)
 begin 
	update tfmarchive.DataArchivingLog
	set ArchiveAndPurgeArchivedOlderThan = @ArchiveAndPurgeArchivedOlderThan
	   ,RowsToArchive = 
	   (select count(1) from tfmarchive.Step 
	    where tranStepId in (select tranStepId from #tranStepId))
	   ,ArchiveStartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and ArchiveStartDate is null
    option (maxdop 0)

	if (select RowsToArchive from tfmarchive.DataArchivingLog 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select @ArchiveAndPurgeArchivedOlderThan = convert(char(10), dateadd(dd,-1*(Retention_days),@StartOfCurrentRun),101)
	      ,@ArchiveBatchSize = ArchiveBatchSize
	from tfmarchive.DataArchivingCfg
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @rc = @ArchiveBatchSize

	while @rc = @ArchiveBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchiveBatchSize) from tfmarchive.Step
		output deleted.* into TFM_Archive.tfmarchive.Step
		where tranStepId in (select tranStepId from #tranStepId)
		option (maxdop 0)

		set @rc = @@rowcount

		update tfmarchive.DataArchivingLog
		set ArchivedRows = isnull(ArchivedRows, 0) + @rc		
		,LastArchiveDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	end
	
	update tfmarchive.DataArchivingLog
	set ArchiveEndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update tfmarchive.DataArchivingLog
	set ArchivingError = 
		'ErrorNumber: '+cast(ERROR_NUMBER() as varchar(100))+' '+
		'ErrorSeverity: '+cast(ERROR_SEVERITY() as varchar(100))+' '+
		'ErrorState: '+cast(ERROR_STATE() as varchar(100))+' '+
		'ErrorLine: '+cast(ERROR_LINE() as varchar(100))+' '+
		'ErrorMessage: '+ERROR_MESSAGE()
    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--5. 
set @tbl = 'tfmarchive.Request'

begin try
while exists
(select 1 from tfmarchive.DataArchivingLog
 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl 
 and exists (select 1 from tfmarchive.DataArchivingCfg
			 where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
			 and Retention_days is not null)
 and ArchiveEndDate is null)
 begin 
	update tfmarchive.DataArchivingLog
	set ArchiveAndPurgeArchivedOlderThan = @ArchiveAndPurgeArchivedOlderThan
	   ,RowsToArchive = 
	   (select count(1) from tfmarchive.Request 
	    where transactionId in (select transactionId from #transactionId))
	   ,ArchiveStartDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	  and ArchiveStartDate is null
    option (maxdop 0)

	if (select RowsToArchive from tfmarchive.DataArchivingLog 
	    where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl) = 0
	  break

	select @ArchiveAndPurgeArchivedOlderThan = convert(char(10), dateadd(dd,-1*(Retention_days),@StartOfCurrentRun),101)
	      ,@ArchiveBatchSize = ArchiveBatchSize
	from tfmarchive.DataArchivingCfg
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl

	set @rc = @ArchiveBatchSize

	while @rc = @ArchiveBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchiveBatchSize) from tfmarchive.Request
		output deleted.* into TFM_Archive.tfmarchive.Request
		where transactionId in (select transactionId from #transactionId)
		option (maxdop 0)

		set @rc = @@rowcount

		update tfmarchive.DataArchivingLog
		set ArchivedRows = isnull(ArchivedRows, 0) + @rc		
		,LastArchiveDate = getdate()
		where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
	end
	
	update tfmarchive.DataArchivingLog
	set ArchiveEndDate = getdate()
	where AppDataType = @AppDataType and workflowId = @workflowId and Tbl = @tbl
end
end try
begin catch
	update tfmarchive.DataArchivingLog
	set ArchivingError = 
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
