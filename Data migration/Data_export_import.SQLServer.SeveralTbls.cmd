echo off

rem Data_export_import.SQLServer.SeveralTbls.cmd

set SourceInstance="PAERSCBBLD0360\CALLTRACKPROD"
set SourceDbName=scfe_calltrack_old
set TargetInstance="PAERSCBBLD0360\CALLTRACKPROD"
set TargetDbName=cfe_calltrack

set bcpDir=F:\capax\bcp

if not exist %bcpDir%\%TargetDbName% (mkdir %bcpDir%\%TargetDbName%)
set bcpDb=%bcpDir%\%TargetDbName%
if not exist %bcpDb%\bcp_err (mkdir %bcpDb%\bcp_err)

set TblList=tblList.txt

for /f %%T in (%TblList%) do (bcp_export_import.SQLServer.cmd %%T %SourceInstance% %SourceDbName%  %TargetInstance% %TargetDbName% %bcpDir% %bcpDb%\bcp_err)