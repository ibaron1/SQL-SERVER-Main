set nocount on

declare @i int, @j int, @j1 int, @n int, @Called varchar(400)
declare @CallingChain varchar(max)

create table #CallingChain(CallingChain varchar(max))

select row_number() over(order by d.id) as rowNumber,
object_name(d.id) 'Calling', object_name(d.depid) 'Called'
into #ProcDepMap
from sysdepends d 
join
(select name from sysobjects where type = 'P') obj
on object_name(d.id) = obj.name
join sysobjects o
on d.depid = o.id and o.type = 'P'

select @n = max(rowNumber) from #ProcDepMap

set @i = 1

while @i <= @n
begin

	select @CallingChain = Calling+' -> ',@Called = Called 
	from #ProcDepMap
	where rowNumber = @i

	select @j = (select top 1 rowNumber from #ProcDepMap
	where Calling = @Called)

	while exists (select rowNumber from #ProcDepMap where Calling = @Called and rowNumber = @j)
	begin

		select @CallingChain = @CallingChain+Called+' -> '
		from #ProcDepMap
		where rowNumber = @j

		select @j = (select top 1 rowNumber from #ProcDepMap
		where Calling = @Called and rowNumber > @j)

	end

	insert #CallingChain
	select @CallingChain

	set @i = @i + 1

end


select * from #CallingChain


drop table #ProcDepMap, #CallingChain

go


