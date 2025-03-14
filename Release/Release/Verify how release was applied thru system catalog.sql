with cte as
(select @@servername as Instance, db_name() as dbName, schema_name(schema_id) as [schema], name, type,
create_date,modify_date,
case when create_date = modify_date then 'created'
else 'modified' end as CreatedOrModified
from sys.objects
where type not in ('S','D','IT','SQ')
and cast(modify_date as DATE)  = cast(GETDATE() as DATE)
)
select * from cte
order by type, CreatedOrModified, modify_date