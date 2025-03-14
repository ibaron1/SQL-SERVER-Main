CREATE OR ALTER PROCEDURE DataExport_Uat.Populate_RealEstateOwned -- exec ControlTower.DataExport_Uat.Populate_RealEstateOwned
AS

BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DROP TABLE IF EXISTS #StepCode;
DROP TABLE IF EXISTS #RealEstateOwned;
DROP TABLE IF EXISTS #ReoStep;
DROP TABLE IF EXISTS #ActualCompletionDate;

DROP TABLE IF EXISTS #StepCode;
CREATE TABLE #StepCode (i INT IDENTITY, StepCode VARCHAR(3));
INSERT INTO #StepCode (StepCode)
VALUES
('264' ) -- CONVEYED TO HUD
, ('277' ) -- VA CONF SALE NO TOC
, ('370' ) -- RRC EXPIRATION DATE
, ('E07' ) -- CASH FOR KEYS ACCEPTED
, ('E71' ) -- EVICTION NOT NEEDED
, ('F66' ) -- 3RD PTY $ RCD/SNT 2 CLNT
, ('P24' ) -- 2ND CONVEY EXT APPROVED
, ('P27' ) -- 3RD CONVEY EXT APPROVED
, ('P29' ) -- CONVEYANCE DUE DATE
, ('P30' ) -- PROPERTY CONVEYED DAMAGED
, ('P41' ) -- CLM CURTAILED NO EXT REQ
, ('Q05' ) -- USDA LOSS CLAIM SUBM
, ('Q16' ) -- CONVEYANCE EXT APPROVED
, ('Q30' ) -- VERIFY HOA PD CURRENT
, ('Q37' ) -- APPROVAL TO CONVEY DAMAGE
, ('Q54' ) -- CLAIM APPROVED BY QA
, ('Q64') -- INITIAL 571 FILED
, ('Q66') -- FINAL 571 FILED
, ('Q68' ) -- FHLMC 104 INITIAL FILED
, ('Q70' ) -- FHLMC 104 FINAL FILED
, ('R54' ) -- REO CLOSING SCHEDULED
, ('R59' ) -- REO APPRAISAL ORDERED
, ('R60' ) -- REO APPRAISAL RECEIVED
, ('R69' ) -- REO PROCEEDS APPLIED
, ('R71' ) -- MA FIRE INSP COMPLETE
, ('Z43' ) -- PST-SALE CLM NOT NEEDED
;

DROP TABLE IF EXISTS #RealEstateOwned;
SELECT REO.LoanNumber
, REO.ReoSetupDate
, REO.ReoStartDate
, REO.ReoStatusCode
, REO.ReoTemplateId
INTO #RealEstateOwned
FROM MspData.BDE.RealEstateOwned AS REO WITH (NOLOCK)
JOIN MspData.Derived.BusinessFields AS BF WITH (NOLOCK) ON
	REO.LoanNumber = BF.LoanNumber
	AND BF.SmClientId <> 99;

DROP TABLE IF EXISTS #ReoStep;
SELECT t.LoanNumber
, t.RsSetupDate
, t.RsStepCode
, t.RsActualCompletionDate
INTO #ReoStep
FROM
	(SELECT   RS.LoanNumber
			, RS.RsSetupDate
			, RS.RsStepCode
			, RS.RsActualCompletionDate
			, ROW_NUMBER() OVER (PARTITION BY RS.LoanNumber, RS.RsStepCode ORDER BY RS.RecordStartDate DESC) rn
	FROM MspData.BDE.ReoStep AS RS WITH (NOLOCK)
	JOIN #RealEstateOwned AS REO ON
		RS.LoanNumber = REO.LoanNumber
		AND RS.RsSetupDate = REO.ReoSetupDate
	JOIN #StepCode AS SC ON
		RS.RsStepCode= SC.StepCode) t
WHERE t.rn = 1
	AND t.RsActualCompletionDate IS NOT NULL;

-- pivots the StepCodes' ActualCompletionDates
DECLARE @v VARCHAR(4000),
		@sql NVARCHAR(4000);

DROP TABLE IF EXISTS #ActualCompletionDate;

CREATE TABLE #ActualCompletionDate (LoanNumber BIGINT, RsSetupDate DATE);
SET @v =
	(SELECT STRING_AGG(CONCAT(QUOTENAME (SC.StepCode), ' date'), ',' )FROM #StepCode AS SC); -- SELECT @v;
SET @sql = N'alter table #ActualCompletionDate add ' + @v;
EXEC (@sql);

SET @v = (SELECT STRING_AGG(QUOTENAME (SC.StepCode), ', ' ) FROM #StepCode AS SC);
SET @sql
	= N'
insert into #ActualCompletionDate (LoanNumber, RsSetupDate, ' + @v
			+ N')
SELECT pvt.LoanNumber, pvt.RsSetupDate, ' + @v
			+ N'
FROM (
	SELECT LoanNumber, RsSetupDate, RsStepCode, RsActualCompletionDate
	FROM #ReoStep
	where RsActualCompletionDate is not null
	) t
PIVOT (MAX(t.RsActualCompletionDate) FOR t.RsStepCode IN (' + @v + N' )) AS pvt;
' ;
--print @sql
EXEC (@sql);

-- use ControlTower;
DROP TABLE IF EXISTS DataExport_Uat.RealEstateOwned;
SELECT    REO.LoanNumber											
		, REO.ReoStartDate											
		, DATEDIFF(DAY, '1900-01-01', REO.ReoSetupDate)			AS RealEstateOwnedId		
		, CASE WHEN REO.ReoStatusCode = 'A' THEN 1 ELSE 0 END		AS IsActiveReo			
		, CASE WHEN REO.ReoStatusCode = 'C' THEN 1 ELSE 0 END		AS IsCompletedReo
		, COALESCE (RTIRPI.ReoProcessId, 0)							AS ReoProcessId
		, ACD.Q37													AS ApprovalToConveyDamagedPropertyDate
		, ACD.E07													AS CashForKeysAcceptedDate
		, ACD.Q54													AS ClaimApprovedByQaDate
		, GREATEST (ACD.P41, ACD.Q16, ACD.P24, ACD.P27, ACD.P29)	AS ConveyanceDueDate
		, GREATEST(ACD.Q16, ACD.P24, ACD.P27)						AS ConveyanceExtensionApprovedDate
		, ACD.[264]													AS ConveyedToHudDate
		, ACD.P30													AS DamagedPropertyConveyedDate
		, ACD.E71													AS EvictionNotNeededDate
		, ACD.Q70													AS Final104ClaimFiledDate
		, ACD.Q66													AS Fina1571ClaimFiledDate
		, ACD.Q30													AS HoaPaidCurrentDate
		, ACD.Q68													AS Initial104ClaimFiledDate
		, ACD.Q64													AS Initial571ClaimFiledDate
		, ACD.R71													AS MaFireInspectionCompletedDate
		, ACD.P41													AS NoConveyanceExtensionRequiredDate
		, ACD.Z43													AS PostSaleClaimNotNeededDate
		, ACD.R54													AS RealEstateOwnedClosingScheduledDate
		, ACD.R59													AS ReoAppraisalOrderedDate
		, ACD.R60													AS ReoAppraisalReceivedDate
		, ACD.R69													AS ReoProceedsAppliedDate
		, ACD.[370]													AS RrcExpirationDate
		, ACD.F66													AS ThirdPartyFundsReceivedDate
		, ACD.Q05													AS UsdaLossClaimSubmissionDate
		, ACD.[277]													AS VaConfirmedSaleNoTocRequiredDate
INTO DataExport_Uat.RealEstateOwned
FROM #RealEstateOwned AS REO
LEFT OUTER JOIN Lookups.ReoTemplateIdReoProcessId AS RTIRPI WITH (NOLOCK) ON
		REO.ReoTemplateId = RTIRPI.ReoTemplateId
LEFT OUTER JOIN #ActualCompletionDate AS ACD ON
	REO.LoanNumber = ACD.LoanNumber
	AND REO.ReoSetupDate = ACD.RsSetupDate;

DROP TABLE IF EXISTS #StepCode;
DROP TABLE IF EXISTS #RealEstateOwned;
DROP TABLE IF EXISTS #ReoStep;
DROP TABLE IF EXISTS #ActualCompletionDate;
END;









































