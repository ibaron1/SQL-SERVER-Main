set nocount on
declare @schema varchar(40) = 'tfmload' --'tfm'
declare @t table(tbl varchar(128))
insert @t
values
('Activity'),
('Payload'),
('Request'),
('Step'),
('RequestKeyAttributes')

select schema_name(o.schema_id)+'.'+o.name, rows
from sys.objects as o
join @t as t
	on o.name = t.tbl
join sysindexes as i
	on i.id = o.object_id
and i.indid in (0,1)
where schema_name(o.schema_id) = @schema

SELECT * FROM core.ControlPurgeOfExpiredArchivedData
--SELECT * FROM core.ControlPurgeOfExpiredArchivedData_History

SELECT * FROM core.ExpiredArchivedDataProcessing
--SELECT * FROM core.ExpiredArchivedDataProcessing_History

select * from core.DataArchivingAndPurgingConfig
