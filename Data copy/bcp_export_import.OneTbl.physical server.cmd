echo on
set bcpbin="D:\databases\100\Tools\Binn"
rem bcp_export_import.OneTbl.cmd

set SybaseInstance=BASELINE04R
set sybpasswd=r8nn9ng3
set SQLInstance="PAERSCBBLD0368\SCTUTILITYPROD"
set Db=rpruwf_prod

set Tbl=grp_work_type_tbl

set bcpDir=C:\tmp\bcp

if not exist %bcpDir%\%Db% (mkdir %bcpDir%\%Db%)
set bcpDb=%bcpDir%\%Db%
if not exist %bcpDb%\bcp_err (mkdir %bcpDb%\bcp_err)

rem Sybase export -> sybase_bcp.exe is on Capax TR server 
bcp %Db%.dbo.%Tbl% out %bcpDb%\tbl.%Db%.bcp -Ux171678 -S%SybaseInstance% -P%sybpasswd% -c -t"|" -r \\n > %bcpDb%\%Tbl%.out

rem SQL Server import

echo truncate table %Tbl% > %bcpDb%\tmp.%Db%.sql
echo go >> %bcpDb%\tmp.%Db%.sql
sqlcmd -S%SQLInstance% -d%Db% -i%bcpDb%\tmp.%Db%.sql
%bcpbin%\bcp %Db%.dbo.%Tbl% in %bcpDb%\tbl.%Db%.bcp -S%SQLInstance% -T -c -t"|" -r \\n -b10000 -m1000000 -e%bcpDb%\bcp_err\%Tbl%.err.txt 
