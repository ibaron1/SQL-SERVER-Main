USE TFM_Archive
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if object_id('core.OnBoardTblArchiving') is not null
  drop proc core.OnBoardTblArchiving
go

/************************************************************************************************************
Author. Eli Baron
Date created. 08-11-2017
Purpose. onboard data archiving for a workflow/application
@ArchivingBatchSize for all tables is set the same; it can be modified using SP core.ModifyArchivingBatchSize
Date modified. 8-29-17
 Moved to core schema
Modified by Eli Baron on 1-12-18
  Replaced params
 @product
,@channel
,@touchpoint
,@operation 
,@mode
,@version 
  by @workflowId as per Jira WMTRTFMSVC-120
*************************************************************************************************************/
create proc core.OnBoardTblArchiving
 @workflowId int
,@RetentionDays int = 7
,@RetentionDaysForArchiving int = 28
,@ArchivingBatchSize int = 100000 
as
set nocount on
set implicit_transactions off
set transaction isolation level read uncommitted

insert core.DataArchivingAndPurgingConfig
(DbName
,DbArchivingName
,AppDataType
,workflowId
,Tbl
,RetentionDays
,RetentionDaysForArchiving
,ArchivingBatchSize)
select 
 db_name()
,db_name()+'_Archive'
,t.schemaName
,w.workflowId
,t.tbl
,@RetentionDays
,@RetentionDaysForArchiving
,@ArchivingBatchSize
from TFM.tfm.Workflow as w
cross join core.TblList as t 
where w.workflowId = @workflowId
and not exists
(select '1' from core.DataArchivingAndPurgingConfig
 where  workflowId = w.workflowId and schemaName = t.schemaName and Tbl = t.Tbl)

GO