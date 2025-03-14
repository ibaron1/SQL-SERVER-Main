/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                 Columnstore and B-Tree indexes together                  */
/****************************************************************************/
use [SQLServerInternals]
go

set nocount on
go

if exists(select * from sys.views v join sys.schemas s on v.schema_id = s.schema_id where v.name = 'vOrders' and s.name = 'dbo') drop view dbo.vOrders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'RecentOrders' and s.name = 'dbo') drop table dbo.RecentOrders;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'RecentOrdersTmp' and s.name = 'dbo') drop table dbo.RecentOrdersTmp;
if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name = 'OldOrders' and s.name = 'dbo') drop table dbo.OldOrders;
if exists(select * from sys.partition_schemes where name = 'psOrders') drop partition scheme psOrders;
if exists(select * from sys.partition_functions where name = 'pfOrders') drop partition function pfOrders;
go

create partition function pfOrders(datetime2(0))
as range right for values('2015-02-01','2015-04-01');

create partition scheme psOrders
as partition pfOrders
all to ([TranData]);
go

create table dbo.RecentOrders
(
	OrderId int not null identity(1,1),
	OrderDate datetime2(0) not null,
	OrderNum varchar(16) not null,
	CustomerId int not null,
	OrderTotal money not null,
	PlaceHolder char(100) null,
)
on [TranData]
go

;with n1(c) as (select 0 union all select 0) -- 2 rows
,n2(c) as (select 0 from n1 as t1 cross join n1 as t2) -- 4 rows
,n3(c) as (select 0 from n2 as t1 cross join n2 as t2) -- 16 rows
,n4(c) as (select 0 from n3 as t1 cross join n3 as t2) -- 256 rows
,n5(c) as (select 0 from n4 as t1 cross join n4 as t2) -- 65,536 rows
,ids(id) as (select row_number() over (order by (select null)) from n5)
insert into dbo.RecentOrders(OrderDate,OrderNum,CustomerId,OrderTotal)
	select dateadd(day,-Id % 30,'2015-03-15')
		,'Order ' + convert(varchar(16),Id)
		,ID % 512
		,ID % 1000 
	from Ids; 
go

create unique clustered index IDX_RecentOrders_OrderDate_OrderId
on dbo.RecentOrders(OrderDate,OrderId)
on psOrders(OrderDate)
go

create nonclustered index IDX_RecentOrders_CustomerId
on dbo.RecentOrders(CustomerId)
on psOrders(OrderDate)
go

create table dbo.OldOrders
(
	OrderId int not null,
	OrderDate datetime2(0) not null,
	OrderNum varchar(16) not null,
	CustomerId int not null,
	OrderTotal money not null,
	PlaceHolder char(100) null,
)
on psOrders(OrderDate)
go

;with n1(c) as (select 0 union all select 0) -- 2 rows
,n2(c) as (select 0 from n1 as t1 cross join n1 as t2) -- 4 rows
,ids(id) as (select row_number() over (order by (select null)) from n2)
insert into dbo.OldOrders(OrderId,OrderDate,OrderNum,CustomerId,OrderTotal)
	select 
		OrderId + (Id + 1) * 100000
		,dateadd(month,-2,OrderDate)
		,'Order ' + convert(varchar(16), OrderId + (id + 1) * 100000)
		,CustomerId
		,OrderTotal
	from dbo.RecentOrders cross join Ids;
go

create clustered columnstore index IDX_OldOrders_CS
on dbo.OldOrders
on psOrders(OrderDate)
go

create view dbo.vOrders(OrderId,OrderDate,OrderNum,CustomerId,OrderTotal)
as
	select OrderId,OrderDate,OrderNum,CustomerId,OrderTotal
	from dbo.RecentOrders
	union all
	select OrderId,OrderDate,OrderNum,CustomerId,OrderTotal
	from dbo.OldOrders
go

set statistics io on

select top 10 CustomerId, count(*) as [Order Cnt], sum(OrderTotal) as [Total Amt]
from dbo.vOrders
group by CustomerId
order by [Total Amt] desc;

set statistics io off
go

-- Rows:
exec sp_spaceused 'dbo.RecentOrders';
exec sp_spaceused 'dbo.OldOrders';
go

create table dbo.RecentOrdersTmp
(
	OrderId int not null,
	OrderDate datetime2(0) not null,
	OrderNum varchar(16) not null,
	CustomerId int not null,
	OrderTotal money not null,
	PlaceHolder char(100) null,

	constraint CHK_RecentOrdersTmp
	check(OrderDate >= '2015-02-01' and OrderDate < '2015-04-01')
)
on [TranData]
go

create unique clustered index IDX_RecentOrdersTmp_OrderDate_OrderId
on dbo.RecentOrdersTmp(OrderDate,OrderId)
go

create nonclustered index IDX_RecentOrdersTmp_CustomerId
on dbo.RecentOrdersTmp(CustomerId)
go

alter table dbo.RecentOrders
switch partition 2 to dbo.RecentOrdersTmp
go

drop index IDX_RecentOrdersTmp_CustomerId on dbo.RecentOrdersTmp;
drop index IDX_RecentOrdersTmp_OrderDate_OrderId on dbo.RecentOrdersTmp;
go

create clustered columnstore index IDX_RecentOrdersTmp_CS
on dbo.RecentOrdersTmp
on [TranData];
go

alter partition function pfOrders() split range ('2015-06-01');
go

alter table dbo.RecentOrdersTmp
switch to dbo.OldOrders
partition 2
go

exec sp_spaceused 'dbo.RecentOrders';
exec sp_spaceused 'dbo.OldOrders';
go


