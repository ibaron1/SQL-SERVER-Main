echo off

rem bcp_export_import.OneTbl.dbs_w_diff_name.cmd

set SybaseInstance=BASELINE20
set sybpasswd=r8nn9ng3
set SQLInstance="PAERSCBBLD0368\PIPELINEPROD"
set SybDb=db_pruwf_prod
set SqlDb=db_pruwf_prod_dummy
set Tbl=team_exception_tbl

set bcpbin=C:"\Program Files\Microsoft SQL Server\100\Tools\Binn"

set bcpDir=C:\Temp\bcp

if not exist %bcpDir%\%Db% (mkdir %bcpDir%\%Db%)
set bcpDb=%bcpDir%\%Db%
if not exist %bcpDb%\bcp_err (mkdir %bcpDb%\bcp_err)

rem Sybase export -> sybase_bcp.exe is on Capax TR server 
sybbcp %SybDb%.dbo.%Tbl% out %bcpDb%\tbl.%SqlDb%.bcp -Ux171678 -S%SybaseInstance% -P%sybpasswd% -c -t"|~|~|" -r \\n > %bcpDb%\%Tbl%.out
rem SQL Server import

echo truncate table %Tbl% > %bcpDb%\tmp.%Db%.sql
echo go >> %bcpDb%\tmp.%Db%.sql
sqlcmd -S%SQLInstance% -d%SqlDb% -Usa -P$atcs!526 -i%bcpDb%\tmp.%Db%.sql
%bcpbin%\bcp %SqlDb%.dbo.%Tbl% in %bcpDb%\tbl.%SqlDb%.bcp -S%SQLInstance% -Usa -P$atcs!526 -c -t"|~|~|" -r \\n -b10000 -m1000000 -e%bcpDb%\bcp_err\%Tbl%.err.txt
