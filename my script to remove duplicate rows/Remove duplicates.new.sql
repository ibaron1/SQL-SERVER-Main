use FALCON_SRF_Rates_QA
go
set nocount on

declare @id varchar(255), @Cnt int, @t datetime, @NumberOfDups int
declare @dups table (id varchar(255), Cnt int)

set @t = GETDATE()

insert @dups
select id, COUNT(*) as Cnt
from srf_main.CounterParty_tmp
group by id
having COUNT(*) > 1

if not exists (select 1 from @dups)
begin
  print 'No duplicates are found'
  return
end

select @NumberOfDups = SUM(Cnt-1) from @dups

print 'Number of duplicates: '+cast(@NumberOfDups as varchar(40))+' , run time to get duplicates: '+cast(DATEDIFF(ss, @t, getdate()) as varchar(40))+' sec'

declare cursor_a cursor fast_forward forward_only for
select * from @dups

set @t = GETDATE()
   
open cursor_a

WHILE 1=1  
BEGIN   

  fetch cursor_a into @id, @Cnt
  
  if @@FETCH_STATUS <> 0
    BREAK
    
  delete top (@Cnt-1) from srf_main.CounterParty_tmp 
  where id = @id
    
END

CLOSE cursor_a   
DEALLOCATE cursor_a

print 'Run_time to delete duplicate rows: '+cast(DATEDIFF(ss, @t, getdate()) as varchar(40))+' sec'

set @t = GETDATE()

delete @dups

insert @dups
select id, COUNT(*) as Cnt
from srf_main.CounterParty_tmp
group by id
having COUNT(*) > 1

print 'Number of duplicates after delete: '+cast(@@rowcount as varchar(40))+' , run time to get duplicates: '+cast(DATEDIFF(ss, @t, getdate()) as varchar(40))+' sec'

--create index i on srf_main.CounterParty_tmp (id)