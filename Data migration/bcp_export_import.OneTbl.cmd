echo off

rem bcp_export_import.OneTbl.cmd

rem C:\Scripts\SQLServer\Data migration

set SybaseInstance=BASELINE04R
set sybpasswd=r8nn9ng3
set SQLInstance="PAERSCBBLD0360\CALLTRACKREPPROD"
set Db=rcfe_calltrack
set Tbl=call_identify_ao_tbl_hist

set bcpDir=C:\TEMP\bcp

if not exist %bcpDir%\%Db% (mkdir %bcpDir%\%Db%)
set bcpDb=%bcpDir%\%Db%
if not exist %bcpDb%\bcp_err (mkdir %bcpDb%\bcp_err)

rem Sybase export -> sybase_bcp.exe is on Capax TR server 
sybbcp %Db%.dbo.%Tbl% out %bcpDb%\tbl.%Db%.bcp -Ux171678 -S%SybaseInstance% -P%sybpasswd% -c -t"|~|~|" -r \\n> %bcpDb%\%Tbl%.out

rem SQL Server import

echo truncate table %Tbl% > %bcpDb%\tmp.%Db%.sql
echo go >> %bcpDb%\tmp.%Db%.sql
sqlcmd -S%SQLInstance% -d%Db% -i%bcpDb%\tmp.%Db%.sql
bcp %Db%.dbo.%Tbl% in %bcpDb%\tbl.%Db%.bcp -S%SQLInstance% -T -c -t"|~|~|" -r \\n -b10000 -m1000000 -e%bcpDb%\bcp_err\%Tbl%.err.txt
