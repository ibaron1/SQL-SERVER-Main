USE FALCON_SRF_CacheQA
GO
if object_id('srf_main.PopulateCounterparty') is not null
  drop proc PopulateCounterparty
go

/****** Object:  StoredProcedure [srf_main].[PopulateCounterparty]    Script Date: 02/22/2013 13:41:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [srf_main].[PopulateCounterparty](@id varchar(255),@targetid varchar(255)) --data type changed
AS
set nocount on
Begin
--DECLARE @id1 int,@targetid1 varchar(255) --data type changed
--SET @id1=@id
--SET @targetid1=@targetid
INSERT INTO FALCON_SRF_Credit_QA.srf_main.CounterParty
	        (   id,
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
				childCOI,
				childCOO,
				phaseInCategory1,
				phaseInCategory2,
				phaseInCategory3,
				centralGovernment,
				centralBanks,
				interNatFinInst
	        )
	
	SELECT TOP 1 @id AS id,CASE parentcpartyid WHEN 'NULL'THEN '' ELSE parentcpartyid END AS parentcpartyid,
	CASE ultimateparent  WHEN 'NULL'THEN '' ELSE  ultimateparent END AS ultimateparent,
	CASE lei WHEN 'NULL'THEN '' ELSE lei END AS  lei,
	CASE avId WHEN 'NULL'THEN '' ELSE  avId END AS avId ,
	CASE categoryCode WHEN 'NULL'THEN '' ELSE  categoryCode END AS categoryCode,
	CASE classification WHEN 'NULL'THEN '' ELSE  classification END AS classification ,
	CASE percentOwned WHEN 'NULL'THEN '' ELSE percentOwned END AS percentOwned  ,
	CASE donotreportflag  WHEN 'NULL'THEN '' ELSE donotreportflag END AS donotreportflag,
	CASE ISNULL(uspersonflag,'') WHEN 'NULL' THEN '' WHEN '' THEN '' 
		 ELSE 'Y' END AS uspersonflag,
	CASE isdaflag WHEN 'NULL'THEN '' ELSE isdaflag END AS isdaflag,
	CASE maskingoverrideflag  WHEN 'NULL'THEN '' ELSE  maskingoverrideflag END AS maskingoverrideflag,
	CASE countryofincorporation  WHEN 'NULL'THEN '' ELSE countryofincorporation END AS countryofincorporation  ,
	CASE countryofoperation  WHEN 'NULL'THEN '' ELSE countryofoperation END AS countryofoperation,
	(select top (1) CASE countryofincorporation  WHEN 'NULL'THEN '' ELSE countryofincorporation END 
	 from srf_cache.D_SDSRefData WHERE id=@id) as childCOI,
	 (select top (1) CASE countryofoperation  WHEN 'NULL'THEN '' ELSE countryofoperation END 
	 from srf_cache.D_SDSRefData WHERE id=@id) as childCOO,
	CASE phaseInCategory1 WHEN 'NULL'THEN '' ELSE phaseInCategory1 END AS phaseInCategory1,
	CASE phaseInCategory2 WHEN 'NULL'THEN '' ELSE phaseInCategory2 END AS phaseInCategory2,
	CASE phaseInCategory3  WHEN 'NULL'THEN '' ELSE phaseInCategory3 END AS phaseInCategory3,
	case centralGovernment WHEN 'NULL'THEN '' ELSE centralGovernment END AS centralGovernment,
	CASE centralBanks WHEN 'NULL'THEN '' ELSE  centralBanks END AS centralBanks,
	CASE interNatFinInst WHEN 'NULL'THEN '' ELSE  interNatFinInst END AS interNatFinInst
	FROM srf_cache.D_SDSRefData WHERE id=@targetid 
End