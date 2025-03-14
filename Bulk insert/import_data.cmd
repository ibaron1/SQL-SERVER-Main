echo off

(for /f "delims=" %%i in (%1) do @echo %%i)>%1.out

sqlcmd -SDZWAS2996\NYTINSH5003,7109 -d TFM -Q"delete FileStage1;"
bcp tfm..FileStage1 in %1 -SDZWAS2996\NYTINSH5003,7109 -T -c