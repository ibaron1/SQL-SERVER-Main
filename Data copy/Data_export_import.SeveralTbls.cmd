echo off

rem Data_export_import.SeveralTbls.cmd

set SybaseInstance=BASELINE23
set SQLInstance="PAERSCBBLD0360\CALLTRACKPROD"
set passwd=r8nn9ng3
set Db=pruwf_prod

set bcpDir=C:\Temp\bcp

if not exist %bcpDir%\%Db% (mkdir %bcpDir%\%Db%)
set bcpDb=%bcpDir%\%Db%
if not exist %bcpDb%\bcp_err (mkdir %bcpDb%\bcp_err)

set TblList=tblList.txt

for /f %%T in (%TblList%) do (bcp_export_import.cmd %%T %SybaseInstance% %SQLInstance% %passwd% %Db% %bcpDir% %bcpDb%)