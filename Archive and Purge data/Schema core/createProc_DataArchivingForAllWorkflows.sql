USE [TFM_Archive]
GO
/****** Object:  StoredProcedure [core].[DataArchivingForAllWorkflows]    Script Date: 7/23/2018 7:42:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/******************************************************************
Author. Eli Baron
Date created. 8-9-17
Purpose. master to archive data
Date modified. 8-29-17
 Moved to core schema
Modified by Eli Baron on 1-20-18
Data archiving for FileLoad table to be done after
all referencing rows from all workflows for the same loadId
are deleted 
Modified by Eli Baron on 2-15-18
Removed cross workflow tables from this workflow based processing
Modified by Eli Baron on 7-2-18
Fix for @RunTime_min
*****************************************************************/
ALTER proc [core].[DataArchivingForAllWorkflows]
@RunTime_min int = 120,
@DataArchivingStartDay date = null,
@AppDataType varchar(20) = 'tfm',
@DbName varchar(128) = 'TFM'
with recompile
as

if @AppDataType not in (select distinct AppDataType from core.DataArchivingAndPurgingConfig)
begin
	declare @msg varchar(100) = 'The provided value '''+@AppDataType+''' for parameter @AppDataType is not valid';
	throw 51000, @msg, 1;
end

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

declare @DataArchivingStart datetime = coalesce(cast(@DataArchivingStartDay as datetime), getdate())
declare @StartOfCurrentRun datetime = getdate()
declare @EndOfCurrentRun char(1) = 'N'
declare @workflowId int

exec core.DataArchiveInitialSteps @AppDataType = @AppDataType,@DataArchivingStarted = @DataArchivingStart, @DbName = @DbName

declare workflow_crsr1 cursor fast_forward for 
select distinct workflowId 
from core.ArchivingDataProcessing
where AppDataType = @AppDataType and workflowId is not null and EndDate is null

open workflow_crsr1

while 1=1
begin
	fetch workflow_crsr1 into @workflowId
	if @@fetch_status <> 0 or @EndOfCurrentRun = 'Y'
		break

	delete core.transactionIdArchiving
	delete core.tranStepIdArchiving
	delete core.activityIdArchiving

	exec core.DataArchivingForWorkflow 
		@RunTime_min = @RunTime_min, 
		@AppDataType = @AppDataType, 
		@workflowId = @workflowId, 
		@StartOfCurrentRun = @StartOfCurrentRun,
		@EndOfCurrentRun = @EndOfCurrentRun output

end

close workflow_crsr1
deallocate workflow_crsr1

if @EndOfCurrentRun <> 'Y' and @RunTime_min > 0
	exec core.DataArchivingAcrossWorkflows
		@RunTime_min = @RunTime_min, 
		@AppDataType = @AppDataType,  
		@StartOfCurrentRun = @StartOfCurrentRun,
		@EndOfCurrentRun = @EndOfCurrentRun output 

exec core.DataArchiveFinalSteps @AppDataType = @AppDataType, @EndOfCurrentRun = @EndOfCurrentRun, @DbName = @DbName


