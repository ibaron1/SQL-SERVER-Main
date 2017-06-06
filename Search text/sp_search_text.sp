USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_search_text]    Script Date: 05/31/2012 18:55:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[sp_search_text] (@searchfor varchar(100),@db varchar(100) = null,@objname varchar(100)=null)
as
set nocount on
set @searchfor = UPPER(@searchfor)
create table #objs (dbname varchar(100) not null,objname varchar(100) not null,line int not null,type varchar(10) null,outstr varchar(max) null)
if @db is null
	DECLARE CR1 CURSOR local READ_ONLY
	FOR select name from sys.databases
	where state_desc <> 'OFFLINE' and database_id > 4 and
	 name not in ('PRUAudit','capax')
	 
else
	DECLARE CR1 CURSOR local READ_ONLY
	FOR select name from master..sysdatabases
	where name =@db

OPEN CR1
FETCH NEXT FROM CR1 INTO @db
WHILE (@@fetch_status = 0)
BEGIN
  if @objname is null
     insert into #objs
     EXEC ('
   select ''' + @db + ''' as dbname,O.name as ObjName,line,O.Type,outstr as FindStr from ' + @db + '.sys.sql_modules M
	   inner join ' + @db + '.sys.objects O on O.object_id=M.object_id 
	   cross apply capax.dbo.fn_split_to_array(definition,char(10))
   where upper(M.definition) like ''%' + @searchfor + '%'' and upper(outstr) like ''%' + @searchfor + '%''
   ')
else
     insert into #objs
     EXEC ('
   select ''' + @db + ''' as dbname,O.name as ObjName,line,O.Type,outstr as FindStr from ' + @db + '.sys.sql_modules M
	   inner join ' + @db + '.sys.objects O on O.object_id=M.object_id and O.name=''' + @objname + '''
	   cross apply capax.dbo.fn_split_to_array(definition,char(10))
   where upper(outstr) like ''%' + @searchfor + '%''
   ')


  FETCH NEXT FROM CR1 INTO @db
END

CLOSE CR1
DEALLOCATE CR1
select * from #objs 
order by dbname,objname

