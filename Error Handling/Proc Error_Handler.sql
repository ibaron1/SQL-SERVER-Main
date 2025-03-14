drop view if exists dbo.vw_ReturnedError
go
create view dbo.vw_ReturnedError
as
select CONCAT('ErrorNumber: ',ERROR_NUMBER(),  
					' ErrorSeverity: ',ERROR_SEVERITY(), 
					' ErrorState: ',ERROR_STATE(),  
					' ErrorProcedure: ',isnull(ERROR_PROCEDURE(),'Ad-Hoc Query'),   
					' ErrorLine: ',  isnull(ERROR_LINE(),0),
					' ErrorMessage: ',ERROR_MESSAGE()) as ReturnedError; 
go


drop table if exists dbo.Errors;

create table dbo.Errors(
ErrorID bigint identity
,Number int
,Severity int
,[State] int
,[Procedure] varchar(100)
,Line int
,[Message] varchar(200)
)
GO
CREATE or alter PROCEDURE dbo.Error_Handler
@returnMessage bit = 'False'
WITH EXEC AS CALLER
AS
BEGIN

  INSERT INTO dbo.Errors (Number,Severity,[State],[Procedure],Line,[Message])
  VALUES (
    ERROR_NUMBER(),
    ERROR_SEVERITY(),
    ERROR_STATE(),
    isnull(ERROR_PROCEDURE(),'Ad-Hoc Query'),
    isnull(ERROR_LINE(),0),
    ERROR_MESSAGE())

  IF(@returnMessage = 'True')
  BEGIN
    select Number,Severity,State,[Procedure],Line,[Message]
    from Errors
    where ErrorID = scope_identity()
  END
END