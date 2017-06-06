/* Returns a table with the space used in all tables of the
*  database.  It's reported with the schema information unlike
*  the system procedure sp_spaceuse.
*
*  sp_spaceused is used to perform the calculations to ensure
*  that the numbers match what SQL Server would report.
*
*  Compatible with sQL Server 2000 and 2005
*
* Example:
exec dbo.dba_SpaceUsed null, 'N'
*
* © Copyright 2007 Andrew Novick http://www.NovickSoftware.com
* This software is provided as is without warrentee of any kind.
* You may use this procedure in any of your SQL Server databases
* including databases that you sell, so long as they contain 
* other unrelated database objects. You may not publish this 
* procedure either in print or electronically.
******************************************************************/

SET NOCOUNT ON

declare  @SourceDB varchar ( 128 ) -- Optional database name
         -- If null, the current database is reported.
		,@SortBy char(1) -- N for name, S for Size
           -- T for table name

set @SourceDB = null
set @SortBy = 'S' 

DECLARE @sql nvarchar (4000)

IF @SourceDB IS NULL BEGIN
	SET @SourceDB = DB_NAME () -- The current DB 
END

--------------------------------------------------------
-- Create and fill a list of the tables in the database.

CREATE TABLE #Tables (	[schema] sysname
                      , TabName sysname )
		
SELECT @sql = 'insert #tables ([schema], [TabName]) 
                  select TABLE_SCHEMA, TABLE_NAME 
		          from ['+ @SourceDB +'].INFORMATION_SCHEMA.TABLES
			          where TABLE_TYPE = ''BASE TABLE'''
EXEC (@sql)


---------------------------------------------------------------
-- #TabSpaceTxt Holds the results of sp_spaceused. 
-- It Doesn't have Schema Info!
CREATE TABLE #TabSpaceTxt (
                         TabName sysname
	                   , [Rows] varchar (11)
	                   , Reserved varchar (18)
					   , Data varchar (18)
	                   , Index_Size varchar ( 18 )
	                   , Unused varchar ( 18 )
                       )
					
---------------------------------------------------------------
-- The result table, with numeric results and Schema name.
CREATE TABLE #TabSpace ( [Schema] sysname
                       , TabName sysname
	                   , [Rows] bigint
	                   , ReservedMB numeric(18,3)
					   , DataMB numeric(18,3)
	                   , Index_SizeMB numeric(18,3)
	                   , UnusedMB numeric(18,3)
                       )

DECLARE @Tab sysname -- table name
      , @Sch sysname -- owner,schema

DECLARE TableCursor CURSOR FOR
    SELECT [SCHEMA], TabNAME 
         FROM #tables

OPEN TableCursor;
FETCH TableCursor into @Sch, @Tab;

WHILE @@FETCH_STATUS = 0 BEGIN

	SELECT @sql = 'exec [' + @SourceDB 
	   + ']..sp_executesql N''insert #TabSpaceTxt exec sp_spaceused '
	   + '''''[' + @Sch + '].[' + @Tab + ']' + '''''''';

	Delete from #TabSpaceTxt; -- Stores 1 result at a time
	EXEC (@sql);

    INSERT INTO #TabSpace
	SELECT @Sch
	     , [TabName]
         , convert(bigint, rows)
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(reserved, len(reserved)-3)) / 1024.0) 
                ReservedMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(data, len(data)-3)) / 1024.0) DataMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(index_size, len(index_size)-3)) / 1024.0) 
                 Index_SizeMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(unused, len([Unused])-3)) / 1024.0) 
                [UnusedMB]
        FROM #TabSpaceTxt;

	FETCH TableCursor into @Sch, @Tab;
END;

CLOSE TableCursor;
DEALLOCATE TableCursor;

-----------------------------------------------------
--Get FKs

declare @Tables table(TABLE_SCHEMA sysname
                      , TabName sysname )

insert @Tables
select TABLE_SCHEMA, TABLE_NAME
from INFORMATION_SCHEMA.TABLES
where TABLE_TYPE = 'BASE TABLE'

SELECT f.name AS ForeignKey,
(select TABLE_SCHEMA from @Tables where TabName = object_name(f.parent_object_id)) as TableSchema,
OBJECT_NAME(f.parent_object_id) AS TableName,
COL_NAME(fc.parent_object_id,
fc.parent_column_id) AS ColumnName,
(select TABLE_SCHEMA from @Tables where TabName = object_name(f.referenced_object_id)) as ReferenceTableSchema,
OBJECT_NAME (f.referenced_object_id) AS ReferenceTableName,
COL_NAME(fc.referenced_object_id,
fc.referenced_column_id) AS ReferenceColumnName
into #FKs
FROM sys.foreign_keys AS f
INNER JOIN sys.foreign_key_columns AS fc
ON f.OBJECT_ID = fc.constraint_object_id

select * from #FKs
order by ReferenceTableName

-----------------------------------------------------
--

SELECT 
s.[Rows], f.*
FROM #FKs f join #TabSpace s
ON s.TabName = f.TableName
ORDER BY s.[Rows] desc

DROP TABLE #Tables
DROP TABLE #TabSpaceTxt
DROP TABLE #TabSpace
drop table #FKs
