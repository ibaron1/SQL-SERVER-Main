select @@servername as sql_server, db_name() as DbName, count(*) as 'Request row count' from tfm.Request
select @@servername as sql_server, db_name() as DbName, count(*) as 'Step row count' from tfm.Step
select @@servername as sql_server, db_name() as DbName, count(*) as 'Activity row count' from tfm.Activity
select @@servername as sql_server, db_name() as DbName, count(*) as 'Payload row count' from tfm.Payload
select @@servername as sql_server, db_name() as DbName, count(*) as 'RequestKeyAttributes row count' from tfm.RequestKeyAttributes
select @@servername as sql_server, db_name() as DbName, count(*) as 'LoadError row count' from tfm.LoadError
select @@servername as sql_server, db_name() as DbName, count(*) as 'LoadErrorHistory row count' from tfm.LoadErrorHistory
select @@servername as sql_server, db_name() as DbName, count(*) as 'FileLoad row count' from tfm.FileLoad
select @@servername as sql_server, db_name() as DbName, count(*) as 'FileLoadHistory row count' from tfm.FileLoadHistory
select @@servername as sql_server, db_name() as DbName, count(*) as 'TransformationError row count' from tfm.TransformationError
select @@servername as sql_server, db_name() as DbName, count(*) as 'TransformationErrorHistory row count' from tfm.TransformationErrorHistory
select @@servername as sql_server, db_name() as DbName, count(*) as 'FileTransformation row count' from tfm.FileTransformation
select @@servername as sql_server, db_name() as DbName, count(*) as 'FileTransformationHistory row count' from tfm.FileTransformationHistory


select o.name, i.rows from sysindexes i
join sys.objects o
on i.id = o.object_id and o.type='U'
where schema_name(o.schema_id) = 'tfm'
and o.name in ('Payload','Activity','Step','RequestKeyAttributes','Request','LoadError',
'LoadErrorHistory','FileLoad','FileLoadHistory','TransformationError','TransformationErrorHistory','FileTransformation','FileTransformationHistory')
and indid in (0,1)

