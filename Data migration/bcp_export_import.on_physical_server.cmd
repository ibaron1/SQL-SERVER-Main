echo off
set bcpbin="D:\databases\100\Tools\Binn"
rem bcp_export_import.cmd

rem Sybase export
rem sybase_bcp %5.dbo.%1 out %6\tbl.%5.bcp -Usa -S%2 -P%4 -c -t"~" > %7\%1.out
bcp %5.dbo.%1 out %6\tbl.%5.bcp -Ux171678 -S%2 -P%4 -c -t"|~|~|" -r \\n > %7\%1.out

rem SQL Server import

echo truncate table %1 > %6\tmp.%5.sql
echo go >> %6\tmp.%5.sql
sqlcmd -Usa -S%3 -d%5 -P$atcs!526 -i%6\tmp.%5.sql
rem bcp %5.dbo.%1 in %6\tbl.%5.bcp -Usa -S%3 -P%4 -c -t"|~|" b10000 -m1000000 -e%7\bcp_err\%1.err.txt
%bcpbin%\bcp %5.dbo.%1 in %6\tbl.%5.bcp -Usa -S%3 -P$atcs!526 -c -t"|~|~|"  -r \\n -b10000 -m1000000 -e%7\bcp_err\%1.err.txt
