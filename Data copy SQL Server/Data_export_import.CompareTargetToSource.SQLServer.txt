echo off

rem Data_export_import.CompareTargetToSource.SQLServer.cmd

set SourceInstance="PAERSCBBLD0363\SCTUTILITYPROD"
set SourceDbName=sgi_services_prod
set TargetInstance="PAERSCBBLD0371\SCTUTILITYALPHA"
set TargetDbName=sgi_services_alpha

set bcpDir=F:\capax\bcp

if not exist %bcpDir%\%TargetDbName% (mkdir %bcpDir%\%TargetDbName%)
set bcpDb=%bcpDir%\%TargetDbName%


set bcpbin=D:\databases\100\Tools\Binn

echo use tempdb > %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo if exists (select 1 from sysobjects where name='SqlServer_tbls') >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo  drop table SqlServer_tbls >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo create table SqlServer_tbls >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo (DbName varchar(30), TABLE_SCHEMA varchar(30), SqlTbl varchar(32), SqlRows# bigint) >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo use %SourceDbName% >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo insert tempdb..SqlServer_tbls >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo select DB_NAME(), TABLE_SCHEMA, TABLE_NAME, i.rowcnt >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo from sysindexes i >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql  
echo join INFORMATION_SCHEMA.TABLES t >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql 
echo on OBJECT_NAME(i.id) = TABLE_NAME >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo and TABLE_TYPE = 'BASE TABLE' and i.indid in (0,1) >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql


sqlcmd -S%SourceInstance% -i%bcpDir%\SybSqlTbl.%TargetDbName%.sql
%bcpbin%\bcp tempdb.dbo.SqlServer_tbls out %bcpDir%\tblList.%SourceDbName%.txt -S%SourceInstance% -T -c -t"|" -r \\n


echo use tempdb > %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql

echo if exists (select 1 from sysobjects where name='SqlServer1_tbls') >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo  drop table SqlServer1_tbls >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo create table SqlServer1_tbls >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo (DbName varchar(30), TABLE_SCHEMA varchar(30), SqlTbl varchar(32), SqlRows# bigint) >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql

echo if exists (select 1 from sysobjects where name='SqlServer2_tbls') >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo  drop table SqlServer2_tbls >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo create table SqlServer2_tbls >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo (DbName varchar(30), TABLE_SCHEMA varchar(30), SqlTbl varchar(32), SqlRows# bigint) >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo use %TargetDbName% >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo insert tempdb..SqlServer2_tbls >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo select DB_NAME(), TABLE_SCHEMA, TABLE_NAME, i.rowcnt >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo from sysindexes i >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql  
echo join INFORMATION_SCHEMA.TABLES t >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql 
echo on OBJECT_NAME(i.id) = TABLE_NAME >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo and TABLE_TYPE = 'BASE TABLE' and i.indid in (0,1) >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql
echo go >> %bcpDir%\SybSqlTbl.%TargetDbName%.sql

sqlcmd -S%TargetInstance% -i%bcpDir%\SybSqlTbl.%TargetDbName%.sql

%bcpbin%\bcp tempdb.dbo.SqlServer1_tbls in %bcpDir%\tblList.%SourceDbName%.txt -S%TargetInstance% -T -c -t"|" -r \\n -e%bcpDir%\SybSqlTbl.%TargetDbName%.err.txt



