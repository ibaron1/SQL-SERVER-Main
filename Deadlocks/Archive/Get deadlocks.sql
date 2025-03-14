declare @deadlock xml

set @deadlock = 'put your deadlock graph here'

select 
 [PagelockObject] = @deadlock.value('/deadlock-list[1]/deadlock[1]/resource-list[1]/pagelock[1]/@objectname', 'varchar(200)'),
 [DeadlockObject] = @deadlock.value('/deadlock-list[1]/deadlock[1]/resource-list[1]/objectlock[1]/@objectname', 'varchar(200)'),
 [Victim] = case when Deadlock.Process.value('@id', 'varchar(50)') = @deadlock.value('/deadlock-list[1]/deadlock[1]/@victim', 'varchar(50)') then 1 else 0 end,
 [Procedure] = Deadlock.Process.value('executionStack[1]/frame[1]/@procname[1]', 'varchar(200)'),
 [LockMode] = Deadlock.Process.value('@lockMode', 'char(1)'),
 [Code] = Deadlock.Process.value('executionStack[1]/frame[1]', 'varchar(1000)'),
 [ClientApp] = Deadlock.Process.value('@clientapp', 'varchar(100)'),
 [HostName] = Deadlock.Process.value('@hostname', 'varchar(20)'),
 [LoginName] = Deadlock.Process.value('@loginname', 'varchar(20)'),
 [TransactionTime] = Deadlock.Process.value('@lasttranstarted', 'datetime'),
 [InputBuffer] = Deadlock.Process.value('inputbuf[1]', 'varchar(1000)')
 from @deadlock.nodes('/deadlock-list/deadlock/process-list/process') as Deadlock(Process)