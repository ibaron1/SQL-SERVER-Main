/*
Author.Jim Crouse

Modified.Eli Baron for Sentry360 2.0 new datamart
Date.9/12/24
*/
CREATE OR ALTER PROCEDURE [DataExport_Dev].[Populate_Bankruptcy_2_0]
AS

	/* Variables */
	DECLARE @EffectiveDate DATE = MspData.DateTimeFunctions.MspEffectiveDate();

	/* Step codes that have never been used but need to be included in the logic */
	DROP TABLE IF EXISTS #UnusedStepCodes;

	CREATE TABLE #UnusedStepCodes (BksStepCode VARCHAR(3));
	INSERT INTO #UnusedStepCodes (BksStepCode)
	VALUES
	('B42')
	, ('B68');

	/* Pivot all step dates (actual) */
	DECLARE @StepList VARCHAR(MAX);

	SELECT @StepList
	= STRING_AGG(CONCAT('[', StepCodes.BksStepCode, ']'), ',')WITHIN GROUP(ORDER BY StepCodes.BksStepCode)
	FROM
		(SELECT BS.BksStepCode
		 FROM MspData.BDE.BankruptcyStep AS BS
		 UNION
		 SELECT USC.BksStepCode
		 FROM #UnusedStepCodes AS USC) AS StepCodes;

		DECLARE @StepCodePivotSql VARCHAR(MAX)
		= CONCAT(
			'
				SELECT *
				into ##BkStepDates
				FROM (SELECT LoanNumber, BksSetupDate, BksStepCode, BksActualCompletionDate FROM MspData.BDE.BankruptcyStep) AS BS
				PIVOT (MAX(BksActualCompletionDate)
				FOR BksStepCode IN (', @StepList, ')) AS PivotSteps');

	DROP TABLE IF EXISTS ##BkStepDates;

	EXEC (@StepCodePivotSql);
	
		/* Pivot all step dates (scheduled) */
	SET @StepCodePivotSql
	= CONCAT (
			'
			SELECT *
			into ##BkStepScheduledDates
			FROM (SELECT LoanNumber, BksSetupDate, BksStepCode, BksScheduledCompletionDate FROM MspData.BDE.BankruptcyStep) AS BS

			PIVOT (MAX(BksScheduledCompletionDate)
			FOR BksStepCode IN (', @StepList, ') ) AS PivotSteps');

	DROP TABLE IF EXISTS ##BkStepScheduledDates;

	EXEC (@StepCodePivotSql);
	
--===============================================================================
DROP TABLE IF EXISTS #BankruptcyFilings;

CREATE TABLE #BankruptcyFilings
(LoanNumber BIGINT
, BankruptcySetupDate DATE
, BankruptcyCaseNumber VARCHAR(20)
, BankruptcyFilingDate DATE
, EndFilingDate DATE);

INSERT INTO #BankruptcyFilings
(LoanNumber
, BankruptcySetupDate
, BankruptcyCaseNumber
, BankruptcyFilingDate
, EndFilingDate)
SELECT t.LoanNumber
, t.BankruptcySetupDate
, t.BankruptcyCaseNumber
, t.BankruptcyFilingDate
, LAG(t.BankruptcyFilingDate, 1, CAST(SYSDATETIME() AS DATE)) OVER (PARTITION BY t.LoanNumber ORDER BY t.BankruptcyFilingDate DESC) EndFilingDate
FROM
	(SELECT B.LoanNumber
		, B.BankruptcySetupDate
		, B.BankruptcyCaseNumber
		, B.BankruptcyFilingDate
		, ROW_NUMBER() OVER (PARTITION BY B.LoanNumber, B.BankruptcyCaseNumber ORDER BY B.BankruptcyFilingDate DESC) rn
		FROM MspData.BDE.Bankruptcy AS B WITH (NOLOCK)
		JOIN MspData.Derived.BusinessFields AS BF WITH (NOLOCK) ON
		B.LoanNumber = BF.LoanNumber
		AND BF.SmClientId <> 99) t
WHERE t.rn = 1;

