USE ServiceMac_Dev
GO

DROP PROC IF EXISTS Processing.Generate_Missing_Columns_Procedure
GO
CREATE PROCEDURE Processing.Generate_Missing_Columns_Procedure
@TableName VARCHAR(100) = NULL
AS
SET NOCOUNT ON;

DECLARE @ProcedureName VARCHAR(200) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID),'.',OBJECT_NAME(@@PROCID)),
@StartTime DATETIME = CURRENT_TIMESTAMP;

INSERT DataMart_Log.Update_DataMart_History_log(ProcedureName, StartTime)
VALUES(@ProcedureName, @StartTime)

BEGIN TRY

DECLARE @GenerateStaticProc NVARCHAR(MAX) =
CONCAT('CREATE OR ALTER PROCEDURE Processing.Add_Missing_History_Tables_Columns',CHAR(13),'AS',CHAR(13),'SET NOCOUNT ON;',CHAR(13))

    /* Add missing columns */
    DROP TABLE IF EXISTS #MissingColumns;

    SELECT          CONCAT(
                        'ALTER TABLE DataMart_History.'
                      , QUOTENAME(C.TABLE_NAME)
                      , ' ADD '
                      , STRING_AGG(
                            CAST(CONCAT(
                                QUOTENAME(C.COLUMN_NAME)
                              , ' '
                              , C.DATA_TYPE
                              , CASE WHEN C.DATA_TYPE LIKE '%char' THEN
                                         '(' + CONVERT(VARCHAR(5), C.CHARACTER_MAXIMUM_LENGTH) + ')'
                                     WHEN C.DATA_TYPE IN ( 'decimal', 'numeric' ) THEN
                                         '(' + CONVERT(VARCHAR(5), C.NUMERIC_PRECISION) + ','
                                         + CONVERT(VARCHAR(5), C.NUMERIC_SCALE) + ')'
                                     ELSE
                                         ''
                                END) AS VARCHAR(MAX))
                          , ','))                                        AS MissingColumnsSQL
                  , ROW_NUMBER() OVER (ORDER BY QUOTENAME(C.TABLE_NAME)) AS Seq
    INTO #MissingColumns
	FROM            INFORMATION_SCHEMA.COLUMNS AS C
    INNER JOIN      INFORMATION_SCHEMA.TABLES  AS T ON
                    T.TABLE_NAME              = C.TABLE_NAME
                    AND T.TABLE_SCHEMA        = C.TABLE_SCHEMA
    LEFT OUTER JOIN INFORMATION_SCHEMA.COLUMNS AS CHistory ON
                    CHistory.TABLE_NAME       = C.TABLE_NAME
                    AND CHistory.COLUMN_NAME  = C.COLUMN_NAME
                    AND CHistory.TABLE_SCHEMA = 'DataMart_History'
    WHERE           C.TABLE_SCHEMA    = 'DataMart'
                    AND T.TABLE_TYPE  = 'BASE TABLE'
                    AND CHistory.COLUMN_NAME IS NULL
                    AND (T.TABLE_NAME = @TableName OR   @TableName IS NULL)
    GROUP BY        QUOTENAME(C.TABLE_NAME);

    DECLARE @MissingColumnsSeq INT = 1;
    DECLARE @MissingColumnsSQL VARCHAR(MAX);

    WHILE @MissingColumnsSeq <= (SELECT MAX(Seq)FROM #MissingColumns)
        BEGIN
            SELECT  @MissingColumnsSQL = MC.MissingColumnsSQL
            FROM    #MissingColumns AS MC
            WHERE   MC.Seq = @MissingColumnsSeq;

            SET @GenerateStaticProc += CONCAT(@MissingColumnsSQL,';',CHAR(13));

            SET @MissingColumnsSeq = @MissingColumnsSeq + 1;
        END;

--PRINT @GenerateStaticProc
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