USE [TFM_Archive]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************************************************************************************
Author. Eli Baron
Date created. 8-9-17
Purpose. Jira WMTRACAPGO-336, End of current archiving cycle or cycle's run, is to be called from PurgeExpiredArchivedDataForAllWorkflows
Date modified. 8-29-17
 Moved to core schema
*****************************************************************************************************************************************/
ALTER proc [core].[PurgeExpiredArchivedDataFinalSteps]
@AppDataType varchar(20),
@EndOfCurrentRun char(1)
as

set nocount on
set transaction isolation level read uncommitted
set dateformat mdy

update core.ControlPurgeOfExpiredArchivedData
set Updated_DbSpace_Used_GB = Space_used_in_GB
,Updated_DbAvailable_Space_GB = Available_Space_in_GB
,Updated_Percent_Used = Percent_Used
,CurentRunEnded = getdate()
,DataPurgeEnded = case when @EndOfCurrentRun = 'N' then getdate() end
from dbo.dbstats
where  ControlPurgeOfExpiredArchivedData.DbName = db_name() and AppDataType = @AppDataType

GO

