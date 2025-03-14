--First create the table to hold data from dbcc sqlperf 
CREATE TABLE LogSpaceUsage (
DBName                Sysname,
LogSize_MB            Numeric(12,7),
LogSpaceUsed_Percent  Numeric(9,6),
Status                TinyInt,
UsageStatTimeStamp    SmallDateTime
)

--Create Procedures here one by one
-- Proc 1
CREATE PROCEDURE LogUsageInfo
AS
SET NOCOUNT ON
    BEGIN
        dbcc sqlperf(logspace)
    END
GO
-- Proc 2
CREATE PROCEDURE FindLogSpaceUsage
(
    @UsageStatTimeStamp    SmallDateTime =NULL
)
AS
SET NOCOUNT ON
DECLARE
    @CurrentTime    SmallDatetime
    BEGIN
        Create Table #tmpLogSpaceUsage
        (
        DBName                Sysname,
        LogSize_MB            Numeric(12,7),
        LogSpaceUsed_Percent  Numeric(9,6),
        Status                TinyInt,
        UsageStatTimeStamp    SmallDateTime
        )

        -- Get the Log Space Usage data
        INSERT INTO #tmpLogSpaceUsage
        (
        DBName,
        LogSize_MB,
        LogSpaceUsed_Percent,
        Status
        ) 
        exec LogUsageInfo

        -- Get Current Date Time -
        SET @CurrentTime = getdate()

        --  Fill in timestamp of log space usage report
        UPDATE #tmpLogSpaceUsage
        SET UsageStatTimeStamp = @CurrentTime

        -- Populate your table created
        INSERT LogSpaceUsage
        SELECT
                DBName,
                LogSize_MB,
                LogSpaceUsed_Percent,
                Status,
                UsageStatTimeStamp
        FROM #tmpLogSpaceUsage 

        -- Fetch data from your table. UsageStatTimeStamp would give you the timestamp to filter
        -- on any particular time instance.
        IF (@UsageStatTimeStamp IS NULL)
            SELECT *
            FROM LogSpaceUsage
            WHERE UsageStatTimeStamp = @CurrentTime
        ELSE
            SELECT *
            FROM LogSpaceUsage
            WHERE UsageStatTimeStamp = @UsageStatTimeStamp
    END
GO

 --Finally, get your data.
EXEC FindLogSpaceUsage
SELECT * FROM LogSpaceUsage WHERE DBName = 'DBName'


-- To truncate tran log's inactive portion - size will remain but the log pointer will move to the beginning of the log file

DUMP TRAN <DATABASE NAME> WITH NO_LOG

use
DBCC SHRINKFILE
to shrink log size to a less size but not too small otherwise extra space will be allocated if it needs to expand impacting the performance.


