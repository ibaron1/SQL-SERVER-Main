@echo on
set SourceFile=%1 
set TargetFile=%2 

if exist "%TargetFile%" del "%TargetFile%"
for /F "delims=" %%a in ('type "%SourceFile%"') do call :Sub %%a
rem notepad "%TargetFile%"
goto :eof


:Sub
echo %1 >> "%TargetFile%"
if "%2"=="" goto :eof
shift
goto sub
