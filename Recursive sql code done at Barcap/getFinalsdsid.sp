USE FALCON_SRF_CacheQA
GO
/****** Object:  StoredProcedure [srf_main].[getFinalsdsid]    Script Date: 02/22/2013 10:19:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if object_id('srf_main.getFinalsdsid') is not null
  drop proc srf_main.getFinalsdsid
go

CREATE PROC [srf_main].[getFinalsdsid](@id varchar(255),@id_orig varchar(255),@maxlevel INT =4,@id_s varchar(255) OUTPUT, @level int output) --data type changed
AS
BEGIN

set nocount on

DECLARE
--@id_s BIGINT,
 @type VARCHAR(10),
@parentCpartyId varchar(255), --data type changed
@pseudoLegal VARCHAR(10),
@trSdsId varchar(255), --data type changed
@USPersonFlag VARCHAR(10),
@principal varchar(255), --data type changed,
		
@flag_Principal TINYINT

SELECT  @id_s=id,@type=type, -- take just 1 as per Sameer
@parentCpartyId=CASE parentCpartyId
	WHEN 'NULL' THEN 0 ELSE parentCpartyId END ,
	@pseudoLegal=pseudoLegal,@trSdsId=trSdsId,
		@USPersonFlag=USPersonFlag,@principal=principal
		FROM srf_cache.D_SDSRefData
WHERE id=@id 

IF ISNULL(@pseudoLegal,'')='PL' AND ISNULL(@trSdsId,'')<>''
BEGIN
    set @level = @level+1
    if @level < @maxlevel
	    EXEC srf_main.getFinalsdsid @trSdsId,@id_orig,@maxlevel,@id_s OUTPUT, @level output
	else
	    return

END
ELSE IF ISNULL(@type,'')='L'
BEGIN
	
	--Select @id_s
	EXEC srf_main.PopulateCounterparty @id_orig,@id_s

	RETURN @id_s
END
ELSE IF ISNULL(@type,'')<>''
BEGIN
	--PRINT @id
	set @level = @level+1
    if @level <= @maxlevel
	  EXEC srf_main.getFinalsdsid @parentCpartyId,@id_orig,@maxlevel, @id_s OUTPUT, @level output
    else
	    return

END

END

GO