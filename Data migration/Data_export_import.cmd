echo off

rem Data_export_import.cmd

set SybaseInstance=BASELINE04R
set SQLInstance="PAERSCBBLD0363\SCTUTILITYPROD"
set passwd=r8nn9ng3
set Db=rpruwf_prod

set bcpDir=C:\Temp\bcp

if not exist %bcpDir%\%Db% (mkdir %bcpDir%\%Db%)
set bcpDb=%bcpDir%\%Db%
if not exist %bcpDb%\bcp_err (mkdir %bcpDb%\bcp_err)

echo set nocount on > %bcpDir%\tbl.%Db%.sql
echo go >> %bcpDir%\tbl.%Db%.sql
echo select name from sysobjects where type='U' >> %bcpDir%\tbl.%Db%.sql
echo go >> %bcpDir%\tbl.%Db%.sql

isql -Ux171678 -S%SybaseInstance% -P%passwd% -D%Db% -b -i%bcpDir%\tbl.%Db%.sql -o%bcpDir%\tblList.%Db%.txt

set TblList=%bcpDir%\tblList.%Db%.txt

for /f %%T in (%TblList%) do (bcp_export_import.cmd %%T %SybaseInstance% %SQLInstance% %passwd% %Db% %bcpDir% %bcpDb%)