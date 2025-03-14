set quoted_identifier on
go
-- sql server must be a counterpart of sybase server
exec capax..usp_compare_result @db='cmxdb',
@syb_srv='CMX7992',
@syb_cmd='select * from ero_esp_labor_line'



-- this is to compare select sybase and sql server specific like outer join
exec capax..usp_compare_result @db='cmxdb',
@syb_srv='CMX799',
@syb_cmd='select * from ero_esp_labor_line',
@sql_cmd='select * from ero_esp_labor_line'

