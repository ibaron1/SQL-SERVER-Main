echo off

rem Data_export_import.SQLServer.allTbls.cmd

set SourceInstance="PAERSCBBLD0363\SCTUTILITYPROD"
set SourceDbName=sgi_services_prod
set TargetInstance="PAERSCBBLD0371\SCTUTILITYALPHA"
set TargetDbName=sgi_services_alpha

set bcpDir=F:\capax\bcp

if not exist %bcpDir%\%TargetDbName% (mkdir %bcpDir%\%TargetDbName%)
set bcpDb=%bcpDir%\%TargetDbName%
if not exist %bcpDb%\bcp_err (mkdir %bcpDb%\bcp_err)

echo set nocount on > %bcpDir%\tbl.%TargetDbName%.sql
echo go >> %bcpDir%\tbl.%TargetDbName%.sql
echo select name as ' ' from sysobjects where type='U' >> %bcpDir%\tbl.%TargetDbName%.sql
echo go >> %bcpDir%\tbl.%TargetDbName%.sql

sqlcmd -S%SourceInstance% -d%SourceDbName% -i%bcpDir%\tbl.%TargetDbName%.sql -o%bcpDir%\tblList.%TargetDbName%.txt

set TblList=%bcpDir%\tblList.%TargetDbName%.txt

for /f %%T in (%TblList%) do (bcp_export_import.SQLServer.cmd %%T %SourceInstance% %SourceDbName%  %TargetInstance% %TargetDbName% %bcpDir% %bcpDb%\bcp_err)