

USE FALCON_SRF_CacheQA
GO
/****** Object:  StoredProcedure [srf_main].[usp_PopulateCounterparty]    Script Date: 02/22/2013 13:41:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
if object_id('srf_main.usp_PopulateCounterparty') is not null
  drop proc srf_main.usp_PopulateCounterparty
go

CREATE PROC [srf_main].[usp_PopulateCounterparty]
AS
set nocount on

declare @D_SDSRefData table(id varchar(255))

declare @id varchar(255)
declare @counter int = 1;

insert @D_SDSRefData
select distinct id from srf_cache.D_SDSRefData -- because clustered index is on id$
order by id

declare cursor_a cursor fast_forward forward_only for
select id from @D_SDSRefData

open cursor_a

WHILE 1=1  
BEGIN  

  fetch cursor_a into @id
  
  if @@FETCH_STATUS <> 0
    BREAK

  ;WITH LookupId (id,
		parentcpartyid,
		ultimateparent,
		lei,
		avId,
		categoryCode,
		classification,
		percentOwned,
		donotreportflag,
		uspersonflag,
		isdaflag,
		maskingoverrideflag,
		countryofincorporation,
		countryofoperation,
		phaseInCategory1,
		phaseInCategory2,
		phaseInCategory3,
		centralGovernment,
		centralBanks,
		interNatFinInst,
		principal,
		trSdsId) AS
	(SELECT @id,
		parentcpartyid,
		ultimateparent,
		lei,
		avId,
		categoryCode,
		classification,
		percentOwned,
		donotreportflag,
		uspersonflag,
		isdaflag,
		maskingoverrideflag,
		countryofincorporation,
		countryofoperation,
		phaseInCategory1,
		phaseInCategory2,
		phaseInCategory3,
		centralGovernment,
		centralBanks,
		interNatFinInst,
		principal,
		trSdsId
	FROM srf_cache.D_SDSRefData
	WHERE id = 
	(SELECT TOP (1) principal FROM srf_cache.D_SDSRefData WHERE id = @id AND 
	 ISNULL(type,'')='L' AND ISNULL(pseudoLegal,'') <> 'PL')
		UNION ALL
	SELECT @id,
		a.parentcpartyid,
		a.ultimateparent,
		a.lei,
		a.avId,
		a.categoryCode,
		a.classification,
		a.percentOwned,
		a.donotreportflag,
		a.uspersonflag,
		a.isdaflag,
		a.maskingoverrideflag,
		a.countryofincorporation,
		a.countryofoperation,
		a.phaseInCategory1,
		a.phaseInCategory2,
		a.phaseInCategory3,
		a.centralGovernment,
		a.centralBanks,
		a.interNatFinInst,
		a.principal,
		a.trSdsId
	FROM srf_cache.D_SDSRefData a
	WHERE id = 
	(SELECT TOP (1) trSdsId FROM srf_cache.D_SDSRefData WHERE id = @id AND 
	 ISNULL(type,'')='L' AND ISNULL(pseudoLegal,'') = 'PL'))
    select id,
    	principal,
    	trSdsId,
		parentcpartyid,
		ultimateparent,
		lei,
		avId,
		categoryCode,
		classification,
		percentOwned,
		donotreportflag,
		uspersonflag,
		isdaflag,
		maskingoverrideflag,
		countryofincorporation,
		countryofoperation,
		phaseInCategory1,
		phaseInCategory2,
		phaseInCategory3,
		centralGovernment,
		centralBanks,
		interNatFinInst
	from LookupId



set @COUNTER += 1

if @COUNTER%1000 = 0 -- print count for every 1000 processed rows -- EB
    PRINT @COUNTER

END


CLOSE cursor_a   
DEALLOCATE cursor_a

go