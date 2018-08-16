--create table tbl (clmn int)

insert tbl
values
(1),
(2)

declare @min_clmn int, @max_clmn int
declare @rowstopurge int, @rowspurged int = 0

select @min_clmn=min(clmn),@max_clmn=max(clmn)
from tbl

select @rowstopurge = count(1) 
from tbl as t
where clmn between @min_clmn and @max_clmn

declare @rc int, @BatchSize int = 10000

set @rc = @BatchSize

	while @rc = @BatchSize
	begin

		delete top (@BatchSize) t
		from tbl as t
		where clmn between @min_clmn and @max_clmn

		set @rc = @@rowcount

		set @rowspurged += @rc

	end

select @rowstopurge as [rows to purge], @rowspurged as [rows purged]