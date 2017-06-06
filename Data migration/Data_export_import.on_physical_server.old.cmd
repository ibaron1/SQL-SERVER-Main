echo off

rem Data_export_import.cmd

set SybaseInstance=BASELINE04R
set SQLInstance="PAERSCBBLD0360\CALLTRACKREPPROD"
set passwd=r8nn9ng3
set Db=reDG_prod

set bcpDir=K:\capax\bcp\calltrackrepprod

if not exist %bcpDir%\%Db% (mkdir %bcpDir%\%Db%)
set bcpDb=%bcpDir%\%Db%
if not exist %bcpDb%\bcp_err (mkdir %bcpDb%\bcp_err)

echo set nocount on > %bcpDir%\tbl.%Db%.sql
echo go >> %bcpDir%\tbl.%Db%.sql
echo select name from sysobjects where type='U' >> %bcpDir%\tbl.%Db%.sql

echo set nocount on > %bcpDir%\tbl.%Db%.sql
echo go >> %bcpDir%\tbl.%Db%.sql
echo SELECT o.name FROM sysindexes i, sysobjects o >> %bcpDir%\tbl.%Db%.sql 
echo WHERE i.id=o.id and indid IN (0, 1, 255) and o.type='U' >> %bcpDir%\tbl.%Db%.sql
echo and rows = 0 >> %bcpDir%\tbl.%Db%.sql
echo go >> %bcpDir%\tbl.%Db%.sql

sqlcmd -h -1 -S%SQLInstance% -i%bcpDir%\tbl.%Db%.sql -o%bcpDir%\tblList.%Db%.txt

isql -Ux171678 -S%SybaseInstance% -P%passwd% -D%Db% -b -i%bcpDir%\tbl.%Db%.sql -o%bcpDir%\tblList.%Db%.txt

set TblList=%bcpDir%\tblList.%Db%.txt

for /f %%T in (%TblList%) do (bcp_export_import.cmd %%T %SybaseInstance% %SQLInstance% %passwd% %Db% %bcpDir% %bcpDb%)