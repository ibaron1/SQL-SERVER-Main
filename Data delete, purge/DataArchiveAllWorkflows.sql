if object_id('tfmarchive.DataArchivingForAllWorkflows') is not null
  drop proc tfmarchive.DataArchivingForAllWorkflows
go

/***************************************************************************************************************
Author. Eli Baron
Date created. 8-9-17
Purpose. Master SP to archive data and purged expired archived data
****************************************************************************************************************/
create proc tfmarchive.DataArchivingForAllWorkflows
@RunTime_min int = 120,
@DataArchivingStartDay date = null,
@AppDataType varchar(20)
as

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare @DataArchivingStart datetime = coalesce(cast(@DataArchivingStartDay as datetime), getdate())
declare @ArchiveOlderThan datetime
declare @StartOfCurrentRun datetime
declare @EndOfCurrentRun char(1) = 'N'
declare @workflowId int

exec tfmarchive.DataArchiveInitialSteps @AppDataType = @AppDataType,@DataArchivingStarted = @DataArchivingStart

declare workflow_crsr1 cursor fast_forward for 
select distinct workflowId 
from tfmarchive.DataArchivingLog
where ArchiveEndDate is null

open workflow_crsr1

while 1=1
begin
	fetch workflow_crsr1 into @workflowId
	if @@fetch_status <> 0 or @EndOfCurrentRun = 'Y'
		break

	set @StartOfCurrentRun = getdate()

	exec tfmarchive.DataArchivingForWorkflow 
		@RunTime_min = @RunTime_min, 
		@AppDataType = @AppDataType, 
		@workflowId = @workflowId, 
		@StartOfCurrentRun = @StartOfCurrentRun,
		@EndOfCurrentRun = @EndOfCurrentRun output
end

close workflow_crsr1
deallocate workflow_crsr1

set @EndOfCurrentRun = 'N'

declare workflow_crsr2 cursor fast_forward for 
select distinct workflowId 
from tfmarchive.DataArchivingLog
where ArchiveEndDate is null

open workflow_crsr2

while 1=1
begin
	fetch workflow_crsr2 into @workflowId
	if @@fetch_status <> 0 or @EndOfCurrentRun = 'Y'
		break

	set @StartOfCurrentRun = getdate()

	exec TFM_Archive.tfmarchive.PurgeArchivedataForWorkflow
		@RunTime_min = @RunTime_min,
		@AppDataType = @AppDataType,
		@workflowId = @workflowId,
		@StartOfCurrentRun =@StartOfCurrentRun,
		@EndOfCurrentRun = @EndOfCurrentRun output
end

close workflow_crsr2
deallocate workflow_crsr2

exec tfmarchive.DataArchiveFinalSteps @AppDataType = @AppDataType, @EndOfCurrentRun = @EndOfCurrentRun