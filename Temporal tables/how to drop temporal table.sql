https://stackoverflow.com/questions/55522278/procedure-to-drop-system-versioned-temporal-tables

You can't just drop a temporal table. You must first disable versioning, which will cause the history table to become an ordinary table. 
Then you can drop both the temporal table and its corresponding history table.

ALTER TABLE [dbo].[TemporalTest] SET ( SYSTEM_VERSIONING = OFF )
GO
DROP TABLE [dbo].[TemporalTest]
GO
DROP TABLE [dbo].[TemporalTestHistory]
GO

I'm looking for a procedure to drop system-versioned temporal tables, ideally without using dynamic SQL. I've looked through the Microsoft documentation and figured out how to get the autogenerated history table name, but I only know a little about cursors and even less about dynamic SQL.

You can't just drop a temporal table. You must first disable versioning, which will cause the history table to become an ordinary table. Then you can drop both the temporal table and its corresponding history table.

ALTER TABLE [dbo].[TemporalTest] SET ( SYSTEM_VERSIONING = OFF )
GO
DROP TABLE [dbo].[TemporalTest]
GO
DROP TABLE [dbo].[TemporalTestHistory]
GO

I am using temporal tables with autogenerated history tables, so I don't know their names. However, the Microsoft docs provide information about how to list the history tables, so I have a way of getting those names.

select schema_name(t.schema_id) as temporal_table_schema,
     t.name as temporal_table_name,
    schema_name(h.schema_id) as history_table_schema,
     h.name as history_table_name,
    case when t.history_retention_period = -1 
        then 'INFINITE' 
        else cast(t.history_retention_period as varchar) + ' ' + 
            t.history_retention_period_unit_desc + 'S'
    end as retention_period
from sys.tables t
    left outer join sys.tables h
        on t.history_table_id = h.object_id
where t.temporal_type = 2
order by temporal_table_schema, temporal_table_name

--proc will generate statements to drop temporal table with auto or manually created history table
CREATE PROCEDURE dbo.DropTemporalTable
  @schema sysname = N'dbo',
  @table  sysname
AS
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

  EXEC sys.sp_executesql @sql;
END
GO