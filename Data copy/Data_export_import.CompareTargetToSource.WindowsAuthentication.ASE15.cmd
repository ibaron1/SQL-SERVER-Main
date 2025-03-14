echo off

rem Data_export_import.CompareTargetToSource.WindowsAuthentication.ASE15.cmd

set SybaseInstance=zonda
set SQLInstance=CMX9003
set passwd=capaxilya1
set Db=cmxgl

set bcpDir=C:\capax\bcp

set bcpDb=%bcpDir%\%Db%

set bcpbin=C:"\Program Files\Microsoft SQL Server\110\Tools\Binn"

echo use %Db% > %bcpDir%\tbl.%Db%.sql
echo go >> %bcpDir%\tbl.%Db%.sql
echo set nocount on >> %bcpDir%\tbl.%Db%.sql
echo go >> %bcpDir%\tbl.%Db%.sql
echo select db_name()+"|"+user_name(o.uid)+"|"+o.name+"|"+convert(varchar(40), row_count(db_id(),o.id)) >> %bcpDir%\tbl.%Db%.sql 
echo from sysindexes i join sysobjects o >> %bcpDir%\tbl.%Db%.sql
echo on i.id = o.id >> %bcpDir%\tbl.%Db%.sql 
echo where type='U' and i.indid  in (0,1)  >> %bcpDir%\tbl.%Db%.sql 
echo go >> %bcpDir%\tbl.%Db%.sql
isql -Ucapaxilya -S%SybaseInstance% -P%passwd% -b -i%bcpDir%\tbl.%Db%.sql -o%bcpDir%\tblList.%Db%.txt

echo use tempdb > %bcpDir%\SybSqlTbl.%Db%.sql
echo go >> %bcpDir%\SybSqlTbl.%Db%.sql
echo if exists (select 1 from sysobjects where name='sybase_tbls') >> %bcpDir%\SybSqlTbl.%Db%.sql
echo  drop table sybase_tbls >> %bcpDir%\SybSqlTbl.%Db%.sql
echo go >> %bcpDir%\SybSqlTbl.%Db%.sql
echo create table sybase_tbls >> %bcpDir%\SybSqlTbl.%Db%.sql
echo (DbName varchar(30), SybOwner varchar(30), SybTbl varchar(32), SybRows# bigint) >> %bcpDir%\SybSqlTbl.%Db%.sql
echo go >> %bcpDir%\SybSqlTbl.%Db%.sql
echo if exists (select 1 from sysobjects where name='SqlServer_tbls') >> %bcpDir%\SybSqlTbl.%Db%.sql
echo  drop table SqlServer_tbls >> %bcpDir%\SybSqlTbl.%Db%.sql
echo go >> %bcpDir%\SybSqlTbl.%Db%.sql
echo create table SqlServer_tbls >> %bcpDir%\SybSqlTbl.%Db%.sql
echo (DbName varchar(30), TABLE_SCHEMA varchar(30), SqlTbl varchar(32), SqlRows# bigint) >> %bcpDir%\SybSqlTbl.%Db%.sql
echo go >> %bcpDir%\SybSqlTbl.%Db%.sql
echo use %Db% >> %bcpDir%\SybSqlTbl.%Db%.sql
echo go >> %bcpDir%\SybSqlTbl.%Db%.sql
echo insert tempdb..SqlServer_tbls >> %bcpDir%\SybSqlTbl.%Db%.sql
echo select DB_NAME(), TABLE_SCHEMA, TABLE_NAME, i.rowcnt >> %bcpDir%\SybSqlTbl.%Db%.sql
echo from sysindexes i >> %bcpDir%\SybSqlTbl.%Db%.sql  
echo join INFORMATION_SCHEMA.TABLES t >> %bcpDir%\SybSqlTbl.%Db%.sql 
echo on OBJECT_NAME(i.id) = TABLE_NAME >> %bcpDir%\SybSqlTbl.%Db%.sql
echo and TABLE_TYPE = 'BASE TABLE' and i.indid in (0,1) >> %bcpDir%\SybSqlTbl.%Db%.sql
echo go >> %bcpDir%\SybSqlTbl.%Db%.sql

sqlcmd -S%SQLInstance% -i%bcpDir%\SybSqlTbl.%Db%.sql

%bcpbin%\bcp tempdb.dbo.sybase_tbls in %bcpDir%\tblList.%Db%.txt -S%SQLInstance% -T -c -t"|" -e%bcpDir%\SybSqlTbl.%Db%.err.txt



