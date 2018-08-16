USE [TFM]
GO
/****** Object:  Trigger [tfm].[trg_I_Workflow]    Script Date: 8/6/2018 3:19:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*******************************************************************
Author. Eli Baron
Date created. 2-32-18
Description. To onboard new workflow for data archiving and purging
*******************************************************************/
ALTER trigger [tfm].[trg_I_Workflow]
on  [tfm].[Workflow] 
after insert
as
set nocount on

declare @workflowId int

select @workflowId = workflowId from inserted

exec tfm.OnBoardTblArchiving @workflowId = @workflowId

if trigger_nestlevel(object_id('tfm.trg_FileLoadReplay') , 'AFTER' , 'DML' ) <= 1 
  return

