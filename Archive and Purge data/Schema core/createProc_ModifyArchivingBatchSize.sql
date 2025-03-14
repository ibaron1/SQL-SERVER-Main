USE [TFM_Archive]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*****************************************************************************
Author. Eli Baron
Date created. 08-11-2017
Purpose. Jira WMTRACAPGO-336, update ArchivingBatchSize for the archived table
Date modified. 8-29-17
 Moved to core schema
******************************************************************************/
ALTER proc [core].[ModifyArchivingBatchSize]
@workflowId int null,
@AppDataType varchar(20),
@Tbl varchar(128),
@ArchivingBatchSize int
as
set nocount on
set implicit_transactions off
set transaction isolation level read uncommitted

update core.DataArchivingAndPurgingConfig
set ArchivingBatchSize = @ArchivingBatchSize
where workflowId = isnull(@workflowId,workflowId) and AppDataType = @AppDataType and Tbl = @Tbl



