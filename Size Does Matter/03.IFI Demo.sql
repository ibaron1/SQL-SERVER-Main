/****************************************************************************/
/*    Size Does Matter: 10 Ways to Reduce DB Size and Improve Performance   */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                               IFI Demo                                   */
/****************************************************************************/
set nocount on
set xact_abort on
go

use master
go

if exists (select * from sys.databases where name ='IFIDemo')
begin
	alter database IFIDemo set single_user with rollback immediate
	drop database IFIDemo
end
go


-- Check if Instant File Initialization is Enabled
select * from sys.dm_server_services
go

-- Clearing Wait Statistics
dbcc sqlperf('sys.dm_os_wait_stats', clear) 
go

-- Trace Flag put extra info to the log
dbcc traceon(3004,3605,-1)
go

create database IFIDemo
on primary
(name = N'IFIDemo_Primary', filename = N'e:\db\IFIDemo.mdf' , size = 200MB , filegrowth = 1000KB)
log on
(name = N'IFIDemo_log', filename = N'e:\db\IFIDemo_log.ldf' , size = 10MB , filegrowth = 1000KB)
go

dbcc traceoff(3004,3605,-1)
go

exec sp_readerrorlog 0,1,'IFIDemo'
go

-- Check wait statistics