drop table if exists dbo.ErrorLog
go
create table dbo.ErrorLog
(procName varchar(100),
errorMsg varchar(200) null)
go

create or alter proc dbo.a_proc
as
select 1/0;
go
create or alter proc dbo.b_proc
as
select cast('abc'as int);
go

-- 1. if all statements is in try-catch execution will be stopped after the 1st exception
begin try
	exec dbo.a_proc
	exec dbo.b_proc
end try
begin catch
	select * from dbo.vw_ReturnedError
end catch

-- 2. to continue all executions each statement in question must be in its own try/catch including While, other loop or cursor
begin try
		insert ErrorLog(procName)
		select 'dbo.a_proc'
	exec dbo.a_proc
end try
begin catch
		update ErrorLog
		set errorMsg = (select ReturnedError from dbo.vw_ReturnedError)
		where procName = 'dbo.a_proc'
end catch
begin try
		insert ErrorLog(procName)
		select 'dbo.b_proc'
	exec dbo.b_proc
end try
begin catch
		update ErrorLog
		set errorMsg = (select ReturnedError from dbo.vw_ReturnedError)
		where procName = 'dbo.b_proc'
end catch
go

select * from ErrorLog