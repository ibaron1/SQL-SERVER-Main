USE [TFM]
GO
/****** Object:  StoredProcedure [tfm].[usp_OnBoardEntitlement]    Script Date: 8/6/2018 3:21:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
Author. Eli Baron
Date created. 9-1-17
Purpose. Add AD group entitiled for specific PCT or super user for all workflows
*****************************************************************************************/
ALTER proc [tfm].[usp_OnBoardEntitlement]
@ADgroup varchar(100),
@SuperUser char(1) = null, --set to 'y' if super user 
@product varchar(100) = null,
@channel varchar(100) = null,
@touchpoint varchar(100) = null
as
set nocount on
set implicit_transactions off 
set transaction isolation level read uncommitted

if @SuperUser is null and not exists 
(select '1' from tfm.Workflow
where product = @product and channel = @channel and touchpoint = @touchpoint)
	throw 51001, 'The provided parameter values are not valid', 16

if @SuperUser = 'y'
begin
	if not exists (select '1' from tfm.entitlement where product = 'All')
	  begin
		insert tfm.entitlement
		values(@ADgroup,'All','All','All')

		return
	  end
	else
		throw 51002, 'Super user was already added', 16	
end
else
if not exists 
		(select '1' from tfm.entitlement
		 where ADgroup = @ADgroup and product = @product and channel = @channel and touchpoint = @touchpoint)
	insert tfm.entitlement
	values(@ADgroup,@product,@channel,@touchpoint)
else
	throw 51003, 'Row exists for the provided parameter values', 16


