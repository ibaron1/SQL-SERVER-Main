USE ServiceMac_Dev
GO
DROP PROC IF EXISTS Processing.Generate_Missing_History_Tables_Procedure
GO
CREATE PROCEDURE Processing.Generate_Missing_History_Tables_Procedure @TableName VARCHAR(100) = NULL
AS
SET NOCOUNT ON;

DECLARE @ProcedureName VARCHAR(200) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID),'.',OBJECT_NAME(@@PROCID)),
@StartTime DATETIME = CURRENT_TIMESTAMP;

INSERT DataMart_Log.Update_DataMart_History_log(ProcedureName, StartTime)
VALUES(@ProcedureName, @StartTime)

BEGIN TRY

DECLARE @GenerateStaticProc NVARCHAR(MAX) =
CONCAT('CREATE OR ALTER PROCEDURE Processing.Create_Missing_History_Tables
AS
SET NOCOUNT ON;',CHAR(13));

    /* Create tables that do not exist */
    DROP TABLE IF EXISTS #MissingTables;

    SELECT          QUOTENAME(T.TABLE_NAME)                                         AS TableName
				  , T.TABLE_NAME                                                    AS TableName_NoBrackets
                  , CONCAT(QUOTENAME(T.TABLE_SCHEMA), '.', QUOTENAME(T.TABLE_NAME)) AS TableName_Full
                  , ROW_NUMBER() OVER (ORDER BY THistory.TABLE_NAME)                AS Seq
    INTO            #MissingTables
    FROM            INFORMATION_SCHEMA.TABLES AS T
    LEFT OUTER JOIN INFORMATION_SCHEMA.TABLES AS THistory ON
                    THistory.TABLE_NAME       = T.TABLE_NAME
                    AND THistory.TABLE_SCHEMA = 'DataMart_History'
    WHERE           T.TABLE_SCHEMA    = 'DataMart'
                    AND T.TABLE_TYPE  = 'BASE TABLE'
                    AND THistory.TABLE_NAME IS NULL
                    AND (T.TABLE_NAME = @TableName OR   @TableName IS NULL);

    DECLARE @MissingTableSeq INT = 1;
    DECLARE @MissingTableName VARCHAR(100);
	DECLARE @MissingTableNameNoBrackets VARCHAR(100);
    DECLARE @MissingTableSelect NVARCHAR(MAX);
    DECLARE @MissingTableCreateSQL VARCHAR(MAX);

    WHILE @MissingTableSeq <= (SELECT   MAX(Seq)FROM #MissingTables)
        BEGIN
            SELECT  @MissingTableName   = MT.TableName
				  , @MissingTableNameNoBrackets = MT.TableName_NoBrackets
                  , @MissingTableSelect = CONCAT('SELECT * FROM ', MT.TableName_Full)
            FROM    #MissingTables AS MT
            WHERE   MT.Seq = @MissingTableSeq;

            SELECT  @MissingTableCreateSQL
                = CONCAT('IF OBJECT_ID(''DataMart_History.',@MissingTableName,''') IS NULL
					BEGIN
						IF COL_LENGTH(''DataMart_History.',@MissingTableName,''', ''RecordEndDate'') IS NOT NULL
						  BEGIN
							  CREATE TABLE DataMart_History.'
							  , @MissingTableName
							, '(RowHash BIGINT,'
							, STRING_AGG(CAST(CONCAT(QUOTENAME(TableInfo.name), ' ', TableInfo.system_type_name) AS VARCHAR(MAX)), ',')
							, ') ON ps_DateByMonthRight(RecordEndDate);
					
							  CREATE CLUSTERED COLUMNSTORE INDEX IX_DataMart_History_'
							, @MissingTableNameNoBrackets
							, '_CCI ON DataMart_History.'
							, @MissingTableName
							, ' ON ps_DateByMonthRight(RecordEndDate);
						  END;
						ELSE
						  BEGIN
							  CREATE TABLE DataMart_History.'
							  , @MissingTableName
							, '(RowHash BIGINT,'
							, STRING_AGG(CAST(CONCAT(QUOTENAME(TableInfo.name), ' ', TableInfo.system_type_name) AS VARCHAR(MAX)), ',')
							, ') ON [Primary];
						  END;
					END')
            FROM    sys.dm_exec_describe_first_result_set(@MissingTableSelect, NULL, 0) AS TableInfo;

            SET @GenerateStaticProc += CONCAT(@MissingTableCreateSQL,';',CHAR(13));

            SET @MissingTableSeq = @MissingTableSeq + 1;
        END;

EXEC (@GenerateStaticProc);

UPDATE DataMart_Log.Update_DataMart_History_log
SET EndTime = CURRENT_TIMESTAMP,
	RunTime_sec = DATEDIFF(ss, @StartTime, CURRENT_TIMESTAMP),
	RunTime = Utilities.ParseTime(DATEDIFF(ss, @StartTime, CURRENT_TIMESTAMP))
WHERE ProcedureName = @ProcedureName AND StartTime = @StartTime;

END TRY
BEGIN CATCH
	UPDATE DataMart_Log.Update_DataMart_History_log
	SET EndTime = CURRENT_TIMESTAMP,
		RunTime_sec = DATEDIFF(ss, @StartTime, CURRENT_TIMESTAMP),
		RunTime = Utilities.ParseTime(DATEDIFF(ss, @StartTime, CURRENT_TIMESTAMP)),
		Error = 
		  CONCAT('ErrorNumber: ',ERROR_NUMBER(),  
				 ' ErrorSeverity: ',ERROR_SEVERITY(), 
				 ' ErrorState: ',ERROR_STATE(),  
				 ' ErrorProcedure: ',ERROR_PROCEDURE(),   
				 ' ErrorLine: ',  ERROR_LINE(),
				 ' ErrorMessage: ',ERROR_MESSAGE()) 
	WHERE ProcedureName = @ProcedureName AND StartTime = @StartTime;

	THROW;
END CATCH
