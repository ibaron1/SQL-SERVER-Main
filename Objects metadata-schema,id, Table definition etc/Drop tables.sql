DECLARE @sql VARCHAR(MAX)='';

SELECT @sql += CONCAT('truncate table ', T. TABLE_SCHEMA, '.' , T. TABLE_NAME, ' ; ', 'drop table ' , T. TABLE_SCHEMA, '.' , T. TABLE_NAME, ' ; ', CHAR(13) )
FROM INFORMATION_SCHEMA. TABLES AS T
WHERE TABLE_TYPE='BASE TABLE'
and TABLE_SCHEMA='EtlStage'
--AND T. TABLE_NAME LIKE '%_old'

SELECT @sql
exec (@sql)