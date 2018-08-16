USE [TFM_Archive]
GO
/****** Object:  StoredProcedure [core].[PurgeExpiredArchivedDataForAllWorkflows]    Script Date: 7/23/2018 8:14:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/***************************************************************************************************
Author. Eli Baron
Date created. 8-22-17
Purpose. master to purge expired archived data
Date modified. 8-29-17
 Moved to core schema 
Modified by Eli Baron on 2-15-18
Removed cross workflow tables from this workflow based processing

Modified by Eli Baron on 6-7-2018
Purpose. Remove use of table variables since they get emptied for large volume, Jira WMTRTFMSVC-319
***************************************************************************************************/
ALTER proc [core].[PurgeExpiredArchivedDataForAllWorkflows]
@RunTime_min int = 120,
@PurgeExpiredArchivedDataStartDay date = null,
@AppDataType varchar(20) = 'tfm'
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

declare @DataPurgeStart datetime = coalesce(cast(@PurgeExpiredArchivedDataStartDay as datetime), getdate())
declare @StartOfCurrentRun datetime = getdate()
declare @EndOfCurrentRun char(1) = 'N'
declare @workflowId int

exec core.PurgeExpiredArchivedDataInitialSteps @AppDataType = @AppDataType,@DataPurgeStart = @DataPurgeStart

declare workflow_crsr1 cursor fast_forward for 
select distinct workflowId 
from core.ExpiredArchivedDataProcessing
where AppDataType = @AppDataType and workflowId is not null and EndDate is null

open workflow_crsr1

while 1=1
begin
	fetch workflow_crsr1 into @workflowId
	if @@fetch_status <> 0 or @EndOfCurrentRun = 'Y'
		break

	delete core.transactionIdPurging
	delete core.activityIdPurging

	exec core.PurgeExpiredArchivedDataForWorkflow 
		@RunTime_min = @RunTime_min, 
		@AppDataType = @AppDataType, 
		@workflowId = @workflowId, 
		@StartOfCurrentRun = @StartOfCurrentRun,
		@EndOfCurrentRun = @EndOfCurrentRun output

end

close workflow_crsr1
deallocate workflow_crsr1

if @EndOfCurrentRun <> 'Y' and @RunTime_min > 0
	exec core.PurgeExpiredDataAcrossWorkflows
		@RunTime_min = @RunTime_min, 
		@AppDataType = @AppDataType, 
		@StartOfCurrentRun = @StartOfCurrentRun,
		@EndOfCurrentRun = @EndOfCurrentRun output 

exec core.PurgeExpiredArchivedDataFinalSteps @AppDataType = @AppDataType, @EndOfCurrentRun = @EndOfCurrentRun

