USE [TFM_Archive]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************************************************************
Author. Eli Baron
Date created. 1-30-18
Purpose. Data archiving of cross flow tables

Modified. Eli B on 2-16-18
Added transformation tables

Modified by Eli Baron on 3-7-18
Code changes to address change in cardinality estimator in version SQLSVR 2014, Jira WMTRTFMSVC-204) 
******************************************************************************************************************************/
ALTER proc [core].[DataArchivingAcrossWorkflows]
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
@ArchiveOlderThan datetime,
@tbl varchar(128),
@rc int

create table #loadIdsForDataArchivingCopy (loadId int)
create table #loadIdsForDataArchivingCopyTmp (loadId int)

select @ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),ctrl.DataArchivingStarted),101)
from core.DataArchivingAndPurgingConfig as cfg
cross join core.ControlOfDataArchiving as ctrl
where cfg.AppDataType = @AppDataType and Tbl = 'FileLoad'

--1 
set @tbl = 'LoadError'

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.LoadError 
	    where loadId in (select loadId from core.loadIdsForDataArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.LoadError
		output deleted.* into tfm.LoadError
		where loadId in (select loadId from core.loadIdsForDataArchiving)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--2
set @tbl = 'LoadErrorHistory'

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.LoadErrorHistory 
	    where loadId in (select loadId from core.loadIdsForDataArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.LoadErrorHistory
		output deleted.* into tfm.LoadErrorHistory
		where loadId in (select loadId from core.loadIdsForDataArchiving)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--3 
set @tbl = 'LoggerError'

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.LoggerError 
	    where loadId in (select loadId from core.loadIdsForDataArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.LoggerError
		output deleted.* into tfm.LoggerError
		where loadId in (select loadId from core.loadIdsForDataArchiving)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--4 
set @tbl = 'LoggerErrorHistory'

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.LoggerErrorHistory 
	    where loadId in (select loadId from core.loadIdsForDataArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.LoggerErrorHistory
		output deleted.* into tfm.LoggerErrorHistory
		where loadId in (select loadId from core.loadIdsForDataArchiving)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--5 
set @tbl = 'FileLoad'

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.FileLoad 
	    where loadId in (select loadId from core.loadIdsForDataArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		insert #loadIdsForDataArchivingCopy
		select * from core.loadIdsForDataArchiving

		while exists (select '1' from #loadIdsForDataArchivingCopy)
		begin
			delete top (5000) from #loadIdsForDataArchivingCopy
			output deleted.* into #loadIdsForDataArchivingCopyTmp

			delete top (@ArchivingBatchSize) f
			output deleted.* into tfm.FileLoad
			from TFM.tfm.FileLoad as f with (forceseek)
			join #loadIdsForDataArchivingCopyTmp as l
			on f.loadId = l.loadId
			option (maxdop 0, recompile)
		
			set @rc = @@rowcount

			update core.ArchivingDataProcessing
			set RowsArchived = isnull(RowsArchived, 0) + @rc
			,LastDate = getdate()
			where AppDataType = @AppDataType and Tbl = @tbl

			truncate table #loadIdsForDataArchivingCopyTmp
		end

		truncate table #loadIdsForDataArchivingCopy
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--6
set @tbl = 'FileLoadHistory'

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from TFM.tfm.FileLoadHistory 
	    where loadId in (select loadId from core.loadIdsForDataArchiving))
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.FileLoadHistory
		output deleted.* into tfm.FileLoadHistory
		where loadId in (select loadId from core.loadIdsForDataArchiving)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--7
set @tbl = 'TransformationError'

create table #TransformationId(TransformationId int)

insert #TransformationId
select TransformationId 
from TFM.tfm.FileTransformation
where TransformationEnded < @ArchiveOlderThan

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from #TransformationId)
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.TransformationError
		output deleted.* into tfm.TransformationError
		where TransformationId in (select TransformationId from #TransformationId)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--8
set @tbl = 'TransformationErrorHistory'

truncate table #TransformationId

insert #TransformationId
select TransformationId
from TFM.tfm.FileTransformation
where TransformationEnded < @ArchiveOlderThan

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from #TransformationId)
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.TransformationErrorHistory
		output deleted.* into tfm.TransformationErrorHistory
		where TransformationId in (select TransformationId from #TransformationId)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--9
set @tbl = 'FileTransformation'

truncate table #TransformationId

insert #TransformationId
select TransformationId
from TFM.tfm.FileTransformation
where TransformationEnded < @ArchiveOlderThan

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from #TransformationId)
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.FileTransformation
		output deleted.* into tfm.FileTransformation
		where TransformationId in (select TransformationId from #TransformationId)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

--10
set @tbl = 'FileTransformationHistory'

truncate table #TransformationId

insert #TransformationId
select TransformationId
from TFM.tfm.FileTransformationHistory
where TransformationEnded < @ArchiveOlderThan

begin try
while exists
(select 1 from core.ArchivingDataProcessing
 where AppDataType = @AppDataType and Tbl = @tbl 
 and exists (select 1 from core.DataArchivingAndPurgingConfig
			 where AppDataType = @AppDataType and Tbl = @tbl
			 and RetentionDays is not null)
 and EndDate is null)
 begin 
	update core.ArchivingDataProcessing
	set ArchiveOlderThan = @ArchiveOlderThan
	   ,RowsToArchive = 
	   (select count(1) from #TransformationId)
	   ,StartDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
	  and StartDate is null
    

	if (select sum(isnull(RowsToArchive,0)) from core.ArchivingDataProcessing 
	    where AppDataType = @AppDataType and Tbl = @tbl) = 0
	  break

	select --@ArchiveOlderThan = convert(char(10), dateadd(dd,-1*(RetentionDays),@StartOfCurrentRun),101), --do not remove
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

		delete top (@ArchivingBatchSize) from TFM.tfm.FileTransformationHistory
		output deleted.* into tfm.FileTransformationHistory
		where TransformationId in (select TransformationId from #TransformationId)
		

		set @rc = @@rowcount

		update core.ArchivingDataProcessing
		set RowsArchived = isnull(RowsArchived, 0) + @rc
		,LastDate = getdate()
		where AppDataType = @AppDataType and Tbl = @tbl
	end
	
	update core.ArchivingDataProcessing
	set EndDate = getdate()
	where AppDataType = @AppDataType and Tbl = @tbl
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
    where AppDataType = @AppDataType and Tbl = @tbl

	set @EndOfCurrentRun = 'Y'
	goto EndOfCurrentRun
end catch

EndOfCurrentRun:

