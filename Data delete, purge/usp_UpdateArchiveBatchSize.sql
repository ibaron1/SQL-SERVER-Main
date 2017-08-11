USE TFM
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if object_id('tfmarchive.usp_ModifyArchiveBatchSize') is not null
  drop proc tfmarchive.usp_ModifyArchiveBatchSize
go

/************************************************************
Author. Eli Baron
Date created. 08-11-2017
Purpose. update ArchiveBatchSize for the archived table
************************************************************/
create proc tfmarchive.usp_ModifyArchiveBatchSize
@workflowId int,
@Tbl varchar(128),
@ArchiveBatchSize int
as
set nocount on
set implicit_transactions off
set transaction isolation level read uncommitted

update tfmarchive.DataArchivingCfg
set ArchiveBatchSize = @ArchiveBatchSize
where workflowId = workflowId and Tbl = @Tbl
