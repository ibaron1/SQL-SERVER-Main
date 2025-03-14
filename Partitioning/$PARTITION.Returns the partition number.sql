https://learn.microsoft.com/en-us/sql/t-sql/functions/partition-transact-sql?view=sql-server-ver16&f1url=%3FappId%3DDev15IDEF1%26l%3DEN-US%26k%3Dk(%24partition_TSQL)%3Bk(sql13.swb.tsqlresults.f1)%3Bk(sql13.swb.tsqlquery.f1)%3Bk(MiscellaneousFilesProject)%3Bk(DevLang-TSQL)%26rd%3Dtrue

Returns the partition number into which a set of partitioning column values would be mapped for any specified partition function.

[ database_name. ] $PARTITION.partition_function_name(expression)  

CREATE PARTITION FUNCTION RangePF1 ( INT )  
AS RANGE LEFT FOR VALUES (10, 100, 1000) ;  
GO

SELECT $PARTITION.RangePF1 (10) ;  
GO  

CREATE PARTITION SCHEME RangePS1  
    AS PARTITION RangePF1  
    ALL TO ('PRIMARY') ;  
GO  

CREATE TABLE dbo.PartitionTable (col1 int PRIMARY KEY, col2 char(10))  
    ON RangePS1 (col1) ;  
GO

INSERT dbo.PartitionTable (col1, col2)
VALUES ((1,'a row'),(100,'another row'),(500,'another row'),(1000,'another row'))


SELECT 
	$PARTITION.RangePF1(col1) AS Partition,   
	COUNT(*) AS [COUNT] 
FROM dbo.PartitionTable
GROUP BY $PARTITION.RangePF1(col1)  
ORDER BY Partition ;  
GO  