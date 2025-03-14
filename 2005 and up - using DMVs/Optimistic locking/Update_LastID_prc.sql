use riskbook
go
if exists (select '1' from sysobjects where name = 'Update_LastID' and type='P')
  drop proc Update_LastID
go

create proc Update_LastID
@name varchar(50), @lastID int output
as
/********
This SP will increment lastID by 1 using snapshot isolation level for concurrent update
for concurrent update
08/11/2009 by Ilya Baron
********/
declare @rowid rowversion 

while 1=1
begin
  select @lastID = lastID+1, @rowid = rowid
  from _LastID
  where name = @name

  update _LastID
  set lastID = lastID+1
  from _LastID with (rowlock)
  where name = @name
  and rowid = @rowid

  if @@rowcount <> 0
     break
end

go

go
GRANT EXECUTE ON Update_LastID TO fcTruView_db
go
GRANT EXECUTE ON Update_LastID TO maintenance
go
GRANT EXECUTE ON Update_LastID TO PRDSP
go