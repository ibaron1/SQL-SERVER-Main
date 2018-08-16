use TFM_Archive
go
delete [core].[TblList]
where Tbl in ('LoadError','LoadErrorHistory','LoggerError','LoggerErrorHistory','FileLoad','FileLoadHistory')
go