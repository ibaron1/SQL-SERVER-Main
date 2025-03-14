USE [ServiceMac_Dev]
GO


CREATE OR ALTER PROCEDURE [Processing].[Import_DataMartTablesFromEtlStage]
AS
SET NOCOUNT ON;

DECLARE @EtlStageTables TABLE (EtlStageTable VARCHAR(4000), ImportTable# int);
DECLARE @EtlStageTable VARCHAR(200);
DECLARE @SQLStr VARCHAR(MAX);
DECLARE @EffectiveDate DATE;

INSERT @EtlStageTables
SELECT T.TABLE_NAME, ROW_NUMBER() OVER (ORDER BY T.TABLE_NAME) AS ImportTable#
FROM INFORMATION_SCHEMA.TABLES  AS T
WHERE T.TABLE_SCHEMA = 'EtlStage';

DECLARE @import TABLE
(ColumnName VARCHAR(4000) NULL,
DataType VARCHAR(100) NULL,
PrimaryKeyIndex TINYINT NULL,
OrdinalPosition INT NULL);

/* Drop all tables in EtlStage before data importfrom ControlTower */
DECLARE @DropTableSQL VARCHAR(MAX);

SELECT  @DropTableSQL = STRING_AGG(CONCAT('DROP TABLE IF EXISTS ', T.TABLE_SCHEMA, '.', T.TABLE_NAME), ';')
FROM    INFORMATION_SCHEMA.TABLES AS T
WHERE   T.TABLE_SCHEMA    = 'DataMart'
        AND T.TABLE_TYPE  = 'BASE TABLE';

EXEC (@DropTableSQL);

SELECT  @EffectiveDate = MED.EffectiveDate
FROM    [SM-SQLDEV.97600FBB54A7.DATABASE.WINDOWS.NET].MspData.DateReference.MspEffectiveDates AS MED;

DECLARE @ImportTable# INT = 1;

DECLARE @MissingOrIncorrectColumns TABLE
(EtlStageTable VARCHAR(4000), 
 [Wrong EtlStage Column Name] VARCHAR(max) NULL,
 [No DevOps.Sentry360_2.0 Title/Column] VARCHAR(max) NULL);

TRUNCATE TABLE DataMart_log.Import_DataMartFromStaging_log;

--BEGIN TRY

WHILE @ImportTable# <= (SELECT MAX(ImportTable#) FROM @EtlStageTables)
BEGIN	

	SELECT @EtlStageTable = EtlStageTable
	FROM @EtlStageTables
	WHERE ImportTable# = @ImportTable#;

	DELETE @import;

	INSERT @import
	SELECT S.Title AS ColumnName
		  ,CASE WHEN S.DataType = 'varchar' THEN
                     CONCAT(S.DataType, '(', S.CharacterLength, ')')
                 WHEN S.DataType = 'decimal' THEN
                     CONCAT(S.DataType, '(', S.DecimalPrecision, ',', ISNULL(S.DecimalScale, 0), ')')
                 ELSE
                     S.DataType
				END	
				AS DataType
          , S.PrimaryKeyIndex
          , ROW_NUMBER() OVER (PARTITION BY S.FileName ORDER BY IIF(S.PrimaryKeyIndex IS NULL, 1, 0), S.PrimaryKeyIndex, S.Title) AS OrdinalPosition
    FROM    DevOps.[Sentry360_2.0] AS S
	INNER JOIN INFORMATION_SCHEMA.TABLES AS T
	ON S.FileName = t.TABLE_NAME
	INNER JOIN INFORMATION_SCHEMA.COLUMNS AS C
	ON T.TABLE_SCHEMA = C.TABLE_SCHEMA
	AND T.TABLE_NAME = C.TABLE_NAME
	AND S.Title = C.COLUMN_NAME
    WHERE   S.WorkItemType  = 'Data Element'
            AND S.State     = 'Development'	
			AND T.TABLE_TYPE  = 'BASE TABLE'
			AND T.TABLE_NAME = @EtlStageTable
			AND T.TABLE_SCHEMA = 'EtlStage'		
            AND S.FileName NOT LIKE '%(Derived)%'
            AND S.Title NOT IN ( 'RecordStartDate', 'RecordEndDate' );

    
	--Wrong columns in Staging table
	INSERT @MissingOrIncorrectColumns (EtlStageTable, [Wrong EtlStage Column Name])
	SELECT @EtlStageTable,  STRING_AGG(C.COLUMN_NAME,', ')
	FROM INFORMATION_SCHEMA.TABLES AS T
	JOIN INFORMATION_SCHEMA.COLUMNS AS C
		ON T.TABLE_SCHEMA	= C.TABLE_SCHEMA
		AND T.TABLE_NAME	= C.TABLE_NAME
		AND T.TABLE_TYPE	= 'BASE TABLE'
		AND T.TABLE_NAME	= @EtlStageTable
		AND T.TABLE_SCHEMA	= 'EtlStage'
	WHERE NOT EXISTS
	(SELECT 1 FROM DevOps.[Sentry360_2.0] AS S
	WHERE   S.WorkItemType	= 'Data Element'
		AND S.State			= 'Development'			
		and S.filename		= @EtlStageTable
		AND S.Title			= C.COLUMN_NAME
		AND S.FileName NOT LIKE '%(Derived)%'
		AND S.Title NOT IN ( 'RecordStartDate', 'RecordEndDate' ));

	--Missing columns as defined in DataMart table's schema
	;WITH cte
	AS
	(SELECT STRING_AGG(S.Title,',') AS Title
		FROM    DevOps.[Sentry360_2.0] AS S
		WHERE S.FileName = @EtlStageTable
		 AND S.State     = 'Development'
		 AND S.FileName NOT LIKE '%(Derived)%'
				AND S.Title NOT IN ( 'RecordStartDate', 'RecordEndDate' )
	AND NOT EXISTS
	(SELECT '1' FROM INFORMATION_SCHEMA.TABLES AS T
	INNER JOIN INFORMATION_SCHEMA.COLUMNS AS C
		ON T.TABLE_SCHEMA = C.TABLE_SCHEMA
		AND T.TABLE_NAME = C.TABLE_NAME
		AND S.Title = C.COLUMN_NAME
		AND T.TABLE_TYPE  = 'BASE TABLE'
				AND T.TABLE_NAME = @EtlStageTable
				AND T.TABLE_SCHEMA = 'EtlStage'))
	UPDATE @MissingOrIncorrectColumns
	SET [No DevOps.Sentry360_2.0 Title/Column] = cte.Title
	FROM cte
	WHERE EtlStageTable = @EtlStageTable
		
	SELECT @SQLStr = 
	CONCAT('SELECT ISNULL(CAST(''',@EffectiveDate,''' AS DATE),'''') AS RecordStartDate, CAST(NULL AS DATE) AS RecordEndDate, ')

	SELECT @SQLStr += 
	CONCAT(STRING_AGG
			(CASE WHEN PrimaryKeyIndex IS NOT NULL 
				  THEN CAST(CONCAT('ISNULL(',IIF(DataType like 'decimal%' OR DataType LIKE '%int','TRY_PARSE','CAST'),'(',ColumnName,' AS ', DataType,'),'''') AS ',ColumnName) AS VARCHAR(MAX))
				  ELSE CAST(CONCAT(IIF(DataType like 'decimal%' OR DataType LIKE '%int','TRY_PARSE','CAST'),'(',ColumnName,' AS ', DataType,') AS ',ColumnName) AS VARCHAR(MAX))
			 END,',')
	 ,' INTO DataMart.',@EtlStageTable,' FROM EtlStage.',@EtlStageTable,';')
	FROM @import;

	EXEC (@SQLStr);

	SET @ImportTable# += 1;

END

/*END TRY
BEGIN CATCH
  INSERT DataMart_log.Import_DataMartFromStaging_log
  SELECT 
	 @EtlStageTable,
	 ERROR_MESSAGE() AS [Error];
  --THROW;
END CATCH*/

-- Exception report
SELECT * FROM  @MissingOrIncorrectColumns

--Create derived table
EXEC Processing.Update_Derived_BusinessFields;
EXEC Processing.BuildTableIndexes_DataMart_Derived;

GO


