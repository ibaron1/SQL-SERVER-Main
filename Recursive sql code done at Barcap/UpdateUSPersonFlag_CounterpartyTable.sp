USE FALCON_SRF_CacheQA
GO


if object_id('srf_main.UpdateUSPersonFlag_CounterpartyTable') is not null
  drop proc srf_main.UpdateUSPersonFlag_CounterpartyTable
go

CREATE PROC [srf_main].[UpdateUSPersonFlag_CounterpartyTable]
@maxLevelOfRecursion int 
AS

set nocount on

Declare @Tempupdatecount int   
Declare @COUNTER int   

DECLARE @uspersonflag VARCHAR(10)

DECLARE @id varchar(255)  --data type changed
DECLARE @id_s varchar(255)  --data type changed
DECLARE @principal varchar(255)  --data type changed

SET @COUNTER = 1  

declare cursor_a cursor fast_forward forward_only for
select * from #ProcessTheseIds
    
open cursor_a

WHILE 1=1  
BEGIN   

BEGIN Try
  fetch cursor_a into @id, @principal
  
  if @@FETCH_STATUS <> 0
    BREAK
  
	SELECT @principal=principal FROM #ProcessTheseIds WHERE id=@id
	
	IF ISNULL(@principal,'')<>'' AND @principal <>'NULL' AND @principal<>0
		EXEC  [srf_main].[getFinalsdsid] @principal,@id,@maxLevelOfRecursion,@id_s=@id_s OUTPUT, @level = 0
	ELSE
		EXEC  [srf_main].[getFinalsdsid] @id,@id,@maxLevelOfRecursion,@id_s=@id_s OUTPUT, @level = 0

END TRY

BEGIN CATCH
	
	 SELECT ERROR_NUMBER() --AS ErrorNumber    
        ,ERROR_SEVERITY() --AS ErrorSeverity    
        ,ERROR_STATE()-- AS ErrorState    
        ,ERROR_LINE () --AS ErrorLine    
        ,ERROR_PROCEDURE()-- AS ErrorProcedure    
        ,ERROR_MESSAGE()-- AS ErrorMessage  
	PRINT 'ID '+@id
	
END CATCH

	
SET @COUNTER +=1

END

CLOSE cursor_a   
DEALLOCATE cursor_a



GO