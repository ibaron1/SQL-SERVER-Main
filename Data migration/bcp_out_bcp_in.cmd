echo off

rem bcp_out_bcp_in.cmd

rem call_details_tbl 40,381,176  rows/6 gb data  / script indexes then drop them and recreate after bcp in
rem call_reason_tbl  153,786,495 rows / 12 gb data
rem call_message_tbl 42,637,334 rows / 6 gb data  

set bcpbin="D:\databases\100\Tools\Binn"
set SQLInstance="PAERSCBBLD0360\CALLTRACKPROD"
set sqlpasswd=$atcs!526
set tbl=call_event_tbl

%bcpbin%\bcp cfe_calltrack_old..%tbl% out F:\capax\tmp\%tbl%.txt -Usa -S%SQLInstance% -P%sqlpasswd% -c -b10000 -t"|~|~|" -e%tbl%.err.out.txt

%bcpbin%\bcp cfe_calltrack..%tbl% in F:\capax\tmp\%tbl%.txt -Usa -S%SQLInstance% -P%sqlpasswd% -c -b10000 -t"|~|~|" -e%tbl%.err.in.txt
