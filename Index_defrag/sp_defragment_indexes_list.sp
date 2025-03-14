create proc sp_defragment_indexes_list 
@table varchar(4000) = null
as
/****
@table
	all tables in db if not specified; comma seperated list of up to 20 tables

SAVE TABLE fraglist IF NEEDED, EACH RUN TRUNCATES IT

****/

/****
create table fraglist (
ObjectName char(400),
ObjectId int,
IndexName char(400),
IndexId int,
Lvl int,
CountPages int,
CountRows int,
MinRecSize int,
MaxRecSize int,
AvgRecSize int,
ForRecCount int,
Extents int,
ExtentSwitches int,
AvgFreeBytes int,
AvgPageDensity int,
ScanDensity decimal,
BestCount int,
ActualCount int,
LogicalFrag decimal,
ExtentFrag decimal)
****/

set nocount on

declare @tablename varchar (100),
@execstr varchar (400),
@objectid int,
@indexid int,
@frag decimal,
@indexname char(400),
@CountPages int

declare @tablelist table(tbl varchar(100))

if db_name() IN ('master', 'msdb', 'model', 'tempdb')
begin
print 'This procedure should not be run in system databases.'
return
end

truncate table fraglist

if @table is not null
begin
  while datalength(@table) > 0
  begin
    if charindex(',',@table) > 0
    begin
      insert @tablelist
      select substring(@table,1,charindex(',',@table)-1)
      select @table = stuff(@table,1,charindex(',',@table),'')
    end
    else
    begin
      insert @tablelist
      select substring(@table,1,datalength(@table))
      select @table = stuff(@table,1,datalength(@table),'')
    end
  end
end

if @table is not null
declare tables cursor for
select tbl from @tablelist
else
declare tables cursor for
select so.name
from sysobjects so
join sysindexes si
ON so.id = si.id
WHERE so.type ='U'
and si.indid < 2
and si.rows > 0

open tables

-- Loop through all tables in the db
fetch next
from tables
into @tablename

while @@fetch_status = 0
begin
-- Do the showcontig of all indexes of the table
insert into fraglist 
exec ('DBCC SHOWCONTIG (''' + @tablename + ''') WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')

fetch next
from tables
into @tablename
end

-- Close and deallocate the cursor
close tables
deallocate tables

select * from fraglist

GO