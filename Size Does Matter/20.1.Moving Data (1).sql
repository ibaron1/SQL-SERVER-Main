/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                          Moving Data (1)                                 */
/****************************************************************************/
use [SQLServerInternals]
go

if exists(select * from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where s.name = 'dbo' and t.name = 'TranData') drop table dbo.TranData;
if exists(select * from sys.partition_schemes where name = 'psTranData') drop partition scheme psTranData;
if exists(select * from sys.partition_functions	where name = 'pfTranData') drop partition function pfTranData;
go

create table dbo.TranData
(
	OrderDate date not null,
	OrderId int not null identity(1,1),
	OrderNum varchar(32) not null,
	LobColumn varchar(max) null,
	Placeholder char(50) null,
)
textimage_on [TranData]
go

create unique clustered index IDX_TranData_OrderDate_OrderId
on dbo.TranData(OrderDate, OrderId)
on [TranData]
go

declare
	@StartDate datetime = '2020-12-01'

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N1 as T2) -- 512 rows
,IDs(ID) as (select ROW_NUMBER() over (order by (select NULL)) from N5)
insert into dbo.TranData(OrderDate, OrderNum)
	select 
		dateadd(day,[days].ID,@StartDate), 
		'Order: ' + convert(varchar(12),dateadd(day,[days].ID,@StartDate)) + '-' + convert(varchar(5),[orders].Id)
	from IDs [days] cross join IDs [orders]
	where [days].ID <= 395
go

select count(*) from dbo.TranData
go
