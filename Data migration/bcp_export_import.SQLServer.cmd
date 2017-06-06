echo off
rem bcp_export_import.SQLServer.cmd

set bcpbin=D:\databases\100\Tools\Binn


rem export

%bcpbin%\bcp %3.dbo.%1 out %6\tbl.%5.bcp -S%2 -T -c -t"|~|~|" -r \\n > %6\%1.out

rem import

echo truncate table %1 > %6\tmp.%5.sql
echo go >> %6\tmp.%5.sql
sqlcmd -S%4 -d%5 -i%6\tmp.%5.sql

%bcpbin%\bcp %5.dbo.%1 in %6\tbl.%5.bcp -S%4 -T -c -t"|~|~|"  -r \\n -b10000 -m1000000 -e%7\%1.err.txt
