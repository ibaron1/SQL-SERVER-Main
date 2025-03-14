echo off

rem Example.
rem Run_package.cmd NYKPCM05768V05A\FAL_MAIN1_LIVE FALCON_SRF_Credit
rem

dir /b /O N *.sql > fileName.txt

set SQLInstance=%1
set DbName=%2
set LOGFILE=.\Rel_SRF_SRF_RATES12172012.log

echo %SQLInstance%  %DbName%

for %%* in (.) do set CurrDirName=%%~n*
echo %CurrDirName%

echo Please make sure all required files exist in your current directory %CurrDirName%
echo Applying sql scripts to database %DbName% on SQL Server instance %SQLInstance%
echo Applying sql scripts to database %DbName% on SQL Server instance %SQLInstance% > %LOGFILE%

pause


sqlcmd -h -1 -S%SQLInstance% -d%DbName% -Q"SET NOCOUNT ON SELECT ' %DbName% Upgrade Started:' + CONVERT(varchar,GETDATE())"
sqlcmd -h -1 -S%SQLInstance% -d%DbName% -Q"SET NOCOUNT ON SELECT ' %DbName% Upgrade Started:' + CONVERT(varchar,GETDATE())">>%LOGFILE%
echo *****************************************************
echo *****************************************************>>%LOGFILE%

for /f "tokens=*" %%T in (fileName.txt) do call :execSqlFile %SQLInstance% %DbName% %%T %LOGFILE%

sqlcmd -h -1 -S%SQLInstance% -d%DbName% -Q"SET NOCOUNT ON SELECT ' %DbName% Upgrade Ended:' + CONVERT(varchar,GETDATE())">>%LOGFILE%
echo *****************************************************
echo *****************************************************>>%LOGFILE%

del fileName.txt

goto :eof

:execSqlFile

echo SQL Script --%3

echo SQL Script Name  --%3 >>%LOGFILE%
sqlcmd -h -1 -S%SQLInstance% -d%DbName% -Q"SET NOCOUNT ON SELECT ' Started applying sql script %3 :' + CONVERT(varchar,GETDATE())"
sqlcmd -h -1 -S%SQLInstance% -d%DbName% -Q"SET NOCOUNT ON SELECT ' Started applying sql script %3 :' + CONVERT(varchar,GETDATE())">>%LOGFILE%


sqlcmd -S%1 -d%2 -i%3 -w 2000 >> %4

sqlcmd -h -1 -S%SQLInstance% -d%DbName% -Q"SET NOCOUNT ON SELECT ' Ended applying sql script %3 :' + CONVERT(varchar,GETDATE())"
echo ---------------------------------------






