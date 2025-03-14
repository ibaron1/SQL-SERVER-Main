use RISKWORLD
go
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsertDynamicReportOutput]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[InsertDynamicReportOutput]
go
/****** Object:  StoredProcedure [dbo].[InsertDynamicReportOutput]    Script Date: 03/19/2009 22:11:09 ******/

go
SET ANSI_NULLS ON
go

go
SET QUOTED_IDENTIFIER OFF
go

Create Procedure InsertDynamicReportOutput
	(
		@TransactionID int,
		@UserID varchar(50) = NULL,
		@Tree varchar(max) = NULL,
		@Message nvarchar(200) = NULL,
		@Status varchar(10) = NULL,
		@Agent varchar(50) = NULL,
		@CreatedAt datetime
)
as
/******************************************
Modified by Ilya
Combined 2 update statements into 1
09/04/09
******************************************/

declare @query nvarchar(1000)
declare @ParmDefinition nvarchar(400)



SET quoted_identifier, NoCount ON

delete t_DynamicReportOutput where CreatedAt < getdate()-1

if EXISTS( select TransactionID  from t_DynamicReportOutput (nolock) where TransactionID = @TransactionID)
BEGIN

	set @query = 
	"update t_DynamicReportOutput set CreatedAt = @CreatedAt_var, 
	Message = case when not (@Message_var is null or @Message_var = '') then @Message_var else Message end,
	UserID = case when not (@UserID_var is null or @UserID_var = '') then @UserID_var else UserID end,
	Status = case when not (@Status_var is null or @Status_var = '') then @Status_var else Status end,
	Agent = case when not (@Agent_var is null or @Agent_var = '') then @Agent_var else Agent end,
	Tree = case when @Tree_var is not null then @Tree_var else Tree end  
	where TransactionID = @TransactionID_var"

print @query

	set @ParmDefinition = '@CreatedAt_var datetime, @Message_var nvarchar(200), @UserID_var varchar(50), @Status_var varchar(10), @Agent_var varchar(50), @Tree_var varchar(max), @TransactionID_var int'

    EXECUTE sp_executesql @query, @ParmDefinition, @CreatedAt_var = @CreatedAt, @Message_var = @Message, @UserID_var = @UserID, @Status_var = @Status, @Agent_var = @Agent, @Tree_var = @Tree, @TransactionID_var = @TransactionID

END
ELSE
	BEGIN
		--insert -
		INSERT INTO t_DynamicReportOutput
		(TransactionID,Tree,[Message],CreatedAt,Status,Agent,UserID)
		VALUES
		(@TransactionID, @Tree, @Message, @CreatedAt, @Status, @Agent, @UserID)

	END

go
GRANT EXECUTE ON [dbo].[InsertDynamicReportOutput] TO [maintenance]
go
GRANT EXECUTE ON [dbo].[InsertDynamicReportOutput] TO [PRDSP]
go
GRANT EXECUTE on [dbo].[InsertDynamicReportOutput] to [reports]
go
