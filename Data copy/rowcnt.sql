/****
rowcnt
Description 
Returns an estimate of the number of rows in the specified table.

Syntax 
rowcnt(sysindexes.doampg)

Example 1
select name, rowcnt(sysindexes.doampg) 
     from sysindexes
     where name in 
         (select name from sysobjects where type = "U")
****/

/****  in  SQL Server ****/
 -- data rows
select rowcnt 
from  sys.sysindexes
where object_name(id) = 'account_tbl'
and indid in (0,1)



 
 

