use TFM;
select '' as sql_server,'' as DbName,* from TFM_Archive.[core].[vw_TblsNotOnBoardedOrArchived]
union
select @@servername, db_name(), '','',''
