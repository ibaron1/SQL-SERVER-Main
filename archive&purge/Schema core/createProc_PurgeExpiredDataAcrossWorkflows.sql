use TFM_Archive
go
if object_id('core.PurgeExpiredDataAcrossWorkflows') is not null
  drop proc core.PurgeExpiredDataAcrossWorkflows
go
/*******************************************************************************************************************************
Author. Eli Baron
Date created. 1-30-18
Purpose. Data archiving of cross flow tables

Modified. Eli B on 2-16-18
Added transformation tables

Modified by Eli Baron on 3-7-18
Code changes to address change in cardinality estimator in version SQLSVR 2014, Jira WMTRTFMSVC-204) 

Modified by Eli Baron on 6-7-2018
Purpose. Remove use of table variables since they get emptied for large volume, Jira WMTRTFMSVC-319
******************************************************************************************************************************/
create proc [core].[PurgeExpiredDataAcrossWorkflows]
@RunTime_min int,
@AppDataType varchar(20),
@StartOfCurrentRun datetime,
@EndOfCurrentRun char(1) output
with recompile
as

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare @ArchivingBatchSize int, 
@PurgeExpiredDataOlderThan datetime,
@tbl varchar(128),
@rc int

declare @Id int,@maxId int

select @PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),ctrl.DataPurgeStarted),101)
from core.DataArchivingAndPurgingConfig as cfg
cross join core.ControlPurgeOfExpiredArchivedData as ctrl
where cfg.AppDataType = @AppDataType and Tbl = 'FileLoad'

--1 
set @tbl = 'LoadError'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.LoadError 
	    where loadId in (select loadId from core.loadIdsForDataPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.LoadError
		where loadId in (select loadId from core.loadIdsForDataPurging)
		option (maxdop 0)
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--2
set @tbl = 'LoadErrorHistory'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.LoadErrorHistory 
	    where loadId in (select loadId from core.loadIdsForDataPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.LoadErrorHistory
		where loadId in (select loadId from core.loadIdsForDataPurging)
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--3 
set @tbl = 'LoggerError'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.LoggerError 
	    where loadId in (select loadId from core.loadIdsForDataPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    
	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.LoggerError
		where loadId in (select loadId from core.loadIdsForDataPurging)

		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--4 
set @tbl = 'LoggerErrorHistory'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.LoggerErrorHistory 
	    where loadId in (select loadId from core.loadIdsForDataPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.LoggerErrorHistory
		where loadId in (select loadId from core.loadIdsForDataPurging)
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--5 
set @tbl = 'FileLoad'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.FileLoad 
	    where loadId in (select loadId from core.loadIdsForDataPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	select @Id = min(loadId), @maxId = max(loadId) from core.loadIdsForDataPurging

	while @Id <= @maxId
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete f
		from tfm.FileLoad as f --with (forceseek)
		join core.loadIdsForDataPurging as Id
		on f.loadId = Id.loadId
		where Id.loadId >= @Id and Id.loadId < @Id + @ArchivingBatchSize 
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl

		set @Id += @ArchivingBatchSize

	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--6
set @tbl = 'FileLoadHistory'

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from tfm.FileLoadHistory 
	    where loadId in (select loadId from core.loadIdsForDataPurging))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.FileLoadHistory
		where loadId in (select loadId from core.loadIdsForDataPurging)
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--7
set @tbl = 'TransformationError'

create table #TransformationId(TransformationId int)

insert #TransformationId
select TransformationId 
from tfm.FileTransformation
where TransformationEnded < @PurgeExpiredDataOlderThan

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from #TransformationId)
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.TransformationError
		where TransformationId in (select TransformationId from #TransformationId)
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--8
set @tbl = 'TransformationErrorHistory'

truncate table #TransformationId

insert #TransformationId
select TransformationId
from tfm.FileTransformation
where TransformationEnded < @PurgeExpiredDataOlderThan

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from #TransformationId)
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.TransformationErrorHistory
		where TransformationId in (select TransformationId from #TransformationId)

		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--9
set @tbl = 'FileTransformation'

truncate table #TransformationId

insert #TransformationId
select TransformationId
from tfm.FileTransformation
where TransformationEnded < @PurgeExpiredDataOlderThan

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from #TransformationId)
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.FileTransformation
		where TransformationId in (select TransformationId from #TransformationId)
		
		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--10
set @tbl = 'FileTransformationHistory'

truncate table #TransformationId

insert #TransformationId
select TransformationId
from tfm.FileTransformationHistory
where TransformationEnded < @PurgeExpiredDataOlderThan

begin try
while exists
(select 1 from core.ExpiredArchivedDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays+RetentionDaysForArchiving is not null)
 and EndDate is null)
 begin 
	update core.ExpiredArchivedDataProcessing
	set PurgeExpiredDataOlderThan = @PurgeExpiredDataOlderThan
	   ,RowsToPurge = 
	   (select count(1) from #TransformationId)
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToPurge,0)) from core.ExpiredArchivedDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@PurgeExpiredDataOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays+RetentionDaysForArchiving),@StartOfCurrentRun),101), --do not remove
	      @ArchivingBatchSize = ArchivingBatchSize
	from core.DataArchivingAndPurgingConfig
	where AppDataType = @AppDataType and Tbl = @tbl

	set @rc = @ArchivingBatchSize

	while @rc = @ArchivingBatchSize
	begin
		if datediff(mi, @StartOfCurrentRun, getdate()) > @RunTime_min
		begin
			print 'Exceeded run time limit of '+cast(@RunTime_min/60 as varchar(2))+' hrs '+cast(@RunTime_min%60 as varchar(2))+' min'
			print 'Start time '+cast(@StartOfCurrentRun as varchar(24))+' , Current time '+cast(getdate() as varchar(24))
			
			set @EndOfCurrentRun = 'Y'
			goto EndOfCurrentRun
	    end

		delete top (@ArchivingBatchSize) from tfm.FileTransformationHistory
		where TransformationId in (select TransformationId from #TransformationId)

		set @rc = @@rowcount

		update core.ExpiredArchivedDataProcessing
		set RowsPurged = isnull(RowsPurged, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ExpiredArchivedDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

EndOfCurrentRun:


