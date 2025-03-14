use ServiceMac_Dev
go

--CREATE PROCEDURE dbo.DropTemporalTable
declare  
@schema sysname = N'DataMart_Log',  
@table  sysname = 'Update_DailyRuleTables__log'
--AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @sql nvarchar(max) = N'';

  SELECT @sql += N'ALTER TABLE ' + src + N' SET (SYSTEM_VERSIONING = OFF);
    DROP TABLE ' + src  + N';
    DROP TABLE ' + hist + N';'
  FROM
  (
    SELECT src = QUOTENAME(SCHEMA_NAME(t.schema_id))
               + N'.' + QUOTENAME(t.name),
          hist = QUOTENAME(SCHEMA_NAME(h.schema_id))
               + N'.' + QUOTENAME(h.name)
    FROM sys.tables AS t
    INNER JOIN sys.tables AS h
    ON t.history_table_id = h.[object_id]
    WHERE t.temporal_type = 2
      AND t.[schema_id] = SCHEMA_ID(@schema)
      AND t.name = @table
  ) AS x;

  --print @sql
  EXEC sys.sp_executesql @sql;
END
