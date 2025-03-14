/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                          Moving Data (2)                                 */
/****************************************************************************/
set noexec off
go

use [SQLServerInternals]
go

if not exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'TranData')
begin
	raiserror('Please create table dbo.TranData using 20.1.MovingData (1) script',16,1);
	set noexec on
end;
go


select 
	p.partition_number
	,object_name(object_id) as Name
	,filegroup_name(data_space_id) as FileGroup
	,type_desc
from 
	sys.partitions p join sys.allocation_units a on 
		p.partition_id = a.container_id
where 
	object_id = object_id('dbo.TranData')
order by 
	p.partition_number
go

-- Online
create unique clustered index IDX_TranData_OrderDate_OrderId
on dbo.TranData(OrderDate, OrderId)
with (drop_existing=on, online=on)
on [Entities]
go

select 
	p.partition_number
	,object_name(object_id) as Name
	,filegroup_name(data_space_id) as FileGroup
	,type_desc
from 
	sys.partitions p join sys.allocation_units a on 
		p.partition_id = a.container_id
where 
	object_id = object_id('dbo.TranData')
order by 
	p.partition_number
go


-- Workaround
create partition function pfTranData(date)
as range right for values 
('2100-01-01')
go

alter partition function pfTranData()
merge range('2100-01-01')
go

create partition scheme psTranData
as partition pfTranData
all to ([Entities])
go

create unique clustered index IDX_TranData_OrderDate_OrderId
on dbo.TranData(OrderDate, OrderId)
with (drop_existing=on, online=on)
on psTranData(OrderDate)
go



select 
	p.partition_number
	,object_name(object_id) as Name
	,filegroup_name(data_space_id) as FileGroup
	,type_desc
from 
	sys.partitions p join sys.allocation_units a on 
		p.partition_id = a.container_id
where 
	object_id = object_id('dbo.TranData')
order by 
	p.partition_number
go

