select a.DbName,a.TABLE_SCHEMA as SourceTABLE_SCHEMA,a.SqlTbl as SourceSqlTbl,a.SqlRows# as SourceSqlRows#,
b.DbName,b.TABLE_SCHEMA as TargetTABLE_SCHEMA,b.SqlTbl as TargetSqlTbl,b.SqlRows# as TargetSqlRows#,    
(a.SqlRows#-b.SqlRows#) as Diff    
from tempdb..SqlServer1_tbls a 
left join tempdb..SqlServer2_tbls b
on a.TABLE_SCHEMA=b.TABLE_SCHEMA
and a.SqlTbl=b.SqlTbl
and a.SqlRows# = b.SqlRows#
order by a.SqlRows# desc

