echo off

rem Example.
rem Run_package_tst.cmd NYKPCM05768V05A\FAL_MAIN1_LIVE FALCON_SRF_Credit
rem

dir /b *.sql > fileName.txt

set SQLInstance=%1
set DbName=%2
set LOGFILE=.\Rel_SRF_SRF_RATES12172012.log

echo %SQLInstance%  %DbName%

for %%* in (.) do set CurrDirName=%%~n*
echo %CurrDirName%

echo Please make sure all required files exist in your current directory %CurrDirName%
echo Applying sql scripts to database %DbName% on SQL Server instance %SQLInstance%
echo Applying sql scripts to database %DbName% on SQL Server instance %SQLInstance% > %LOGFILE%

for /f "tokens=*" %%T in (fileName.txt) do call :execSqlFile %SQLInstance% %DbName% %%T %LOGFILE%

del fileName.txt

goto :eof

:execSqlFile

echo SQL Script --%3






