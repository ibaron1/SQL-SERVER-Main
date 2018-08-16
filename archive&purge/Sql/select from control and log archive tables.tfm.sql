set nocount on
declare @schema varchar(40) = 'tfmload'
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

SELECT * FROM core.ControlOfDataArchiving
--SELECT * FROM core.ControlOfDataArchiving_History

SELECT * FROM core.ArchivingDataProcessing
--SELECT * FROM core.ArchivingDataProcessing_History

/*
truncate table core.ControlOfDataArchiving
truncate table core.ArchivingDataProcessing

delete core.ControlOfDataArchiving_History
where DataArchivingEnded is null

*/
/*
select * from core.DataArchivingAndPurgingConfig
*/

