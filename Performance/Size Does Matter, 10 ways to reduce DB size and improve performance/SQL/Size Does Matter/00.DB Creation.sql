/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                          Database Creation                               */
/****************************************************************************/
set nocount on
set xact_abort on
go

use master
go

if exists (select * from sys.databases where name ='SQLServerInternals')
begin
	alter database [SQLServerInternals] set single_user with rollback immediate
	drop database [SQLServerInternals]
end
go

create database [SQLServerInternals]
on primary
(name = N'SQLServerInternals_Primary', filename = N'c:\DB\SQLServerInternals.mdf' , size = 4096KB , filegrowth = 1000KB)
,filegroup [Entities]
(name = N'SQLServerInternals_Entities1', filename = N'c:\DB\SQLServerInternals_Entities1.ndf' , size = 100MB , filegrowth = 100MB),
(name = N'SQLServerInternals_Entities2', filename = N'c:\DB\SQLServerInternals_Entities2.ndf' , size = 100MB , filegrowth = 100MB)
,filegroup [TranData]
(name = N'SQLServerInternals_TranData1', filename = N'c:\DB\SQLServerInternals_TranData1.ndf' , size = 100MB , filegrowth = 100MB),
(name = N'SQLServerInternals_TranData2', filename = N'c:\DB\SQLServerInternals_TranData2.ndf' , size = 100MB , filegrowth = 100MB)
log on
(name = N'SQLServerInternals_log', filename = N'c:\DB\SQLServerInternals_log.ldf' , size = 100MB , filegrowth = 10MB)
go

alter database [SQLServerInternals] set recovery simple
alter database [SQLServerInternals] set trustworthy on; -- FOR legacy LOB Compression demo
go

use [SQLServerInternals]
go

create table dbo.Customers
(
	CustomerId uniqueidentifier not null
		constraint DEF_Customers_CustomerId
		default NEWID(),
	CustomerNumber nvarchar(16) not null,
	CustomerName nvarchar(128) not null,
	CreditLimit int null,
	Attributes xml null
)
on [Entities]
go

create unique clustered index IDX_Customers_CustomerId
on dbo.Customers(CustomerId)
on [Entities]
go

create unique nonclustered index IDX_Customers_CustomerNumber
on dbo.Customers(CustomerNumber)
on [Entities]
go

/*
drop table #TempUID
truncate table dbo.Customers
*/

if object_id('tempdb..#TempUID') is not null drop table #TempUID
create table #TempUID(ID uniqueidentifier default NEWID(), Num int)
go

declare
	@I int = 0
	,@X xml

select @X = 
	(select * from master.sys.objects for xml raw, root('Data')) 

while @I < 40
begin
	truncate table #TempUID
	 
	;with n1(c) as (select 0 union all select 0) -- 2 rows
	,n2(c) as (select 0 from n1 as t1 cross join n1 as t2) -- 4 rows
	,n3(c) as (select 0 from n2 as t1 cross join n2 as t2) -- 16 rows
	,n4(c) as (select 0 from n3 as t1 cross join n3 as t2) -- 256 rows
	,n5(c) as (select 0 from n4 as t1 cross join n4 as t2) -- 65,536 rows
	,ids(id) as (select row_number() over (order by (select null)) from n5)
		insert into #TempUID(Num) 
		select ID from Ids

	insert into dbo.Customers(CustomerId, CustomerNumber, CustomerName, CreditLimit, Attributes)
		select ID 
			,convert(nvarchar(16),@I * 65536 + 1 + Num)
			,N'Customer ' + convert(nvarchar(48),ID)
			,Abs(CheckSum(ID))
			,iif(Num % 1000 = 0, @X, NULL)
		from #TempUID
	raiserror('%d',0,1,@I) with nowait
	select @I += 1
end 

