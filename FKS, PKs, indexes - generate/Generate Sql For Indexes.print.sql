set nocount on

declare @schema varchar(20), @tbl varchar(100), 
@index varchar(100), @clmn varchar(100), @is_unique int, @index_id int
declare @keycnt_cur int, @keycnt int, @schema_tblname varchar(100),
@sqlToDropIndex varchar(400), @sqlToCreateIndex varchar(400), @object_id int,
@filegroup_name varchar(200)

declare
Idx_crsr cursor fast_forward forward_only for
select SCHEMA_NAME(o.schema_id) as [schema],
o.name as [Table], o.object_id, i.name as Idx,i.index_id,
i.is_unique, -- 1 - unique, 0 - not unique
i.index_id --= 1  - clustered, > 1 - nonclustered
from sys.objects o join sys.indexes i
on o.object_id = i.object_id and o.type = 'U'
where i.index_id > 0 and is_primary_key <> 1
order by [schema],[Table]

open Idx_crsr

while 1 = 1
  begin 
	fetch Idx_crsr into @schema, @tbl, @object_id, @index, @index_id, @is_unique, @index_id
	
	if @@FETCH_STATUS <> 0
		break

	select @filegroup_name = 
	(select top(1) f.name
	 from sys.filegroups f join sys.indexes i
	 on f.data_space_id = i.data_space_id
	 where i.object_id = @object_id and i.name = @index)

	-- Generate sql for clustered index to recreate it
	-- after index column was modified
	
	select @keycnt = COUNT(*)
	from sys.index_columns
	where object_id = @object_id and index_id = @index_id
	and is_included_column = 0
	
	select @keycnt_cur = 1 --, @schema_tblname = @schema+'.'+@tbl
	
	select @sqlToCreateIndex =
	  'create '+case @is_unique when 1 then 'unique'
								 else ' ' end+
		case when @index_id = 1 then ' clustered '
			 else ' nonclustered ' end+
		'index '+@index+' on '+@schema+'.'+@tbl+'('
	  
	while @keycnt_cur <= @keycnt
	begin
		select @sqlToCreateIndex = @sqlToCreateIndex+
		c.name+case is_descending_key
				when 0 then ' asc' else ' desc' end+
		 case when @keycnt_cur < @keycnt then ',' else ')' end 
		from sys.index_columns ic
		join sys.columns c
		on ic.object_id  = c.object_id
		and c.object_id = @object_id
		and ic.index_id = @index_id
		and ic.column_id = c.column_id 
		where index_column_id = @keycnt_cur and is_included_column = 0

		 		 		 
		set @keycnt_cur = @keycnt_cur+1
	end
	
	select @keycnt = COUNT(*)
	from sys.index_columns
	where object_id = @object_id and index_id = @index_id
	and is_included_column = 1
	
	if @keycnt > 0
	begin
	  select @sqlToCreateIndex = @sqlToCreateIndex+' INCLUDE ('
	  
	  select @keycnt_cur = min(index_column_id)
	  from sys.index_columns ic
		join sys.columns c
		on ic.object_id  = c.object_id
		and c.object_id = 603149194
		and ic.index_id = 3
		and ic.column_id = c.column_id 
		where is_included_column = 1

	  set @keycnt = @keycnt+@keycnt_cur-1

	  while @keycnt_cur <= @keycnt
	  begin	
		select @sqlToCreateIndex = @sqlToCreateIndex+
		c.name+case is_descending_key
				when 0 then ' asc' else ' desc' end+
		 case when @keycnt_cur < @keycnt then ',' else ')' end 
		from sys.index_columns ic
		join sys.columns c
		on ic.object_id  = c.object_id
		and c.object_id = @object_id
		and ic.index_id = @index_id
		and ic.column_id = c.column_id 
		where index_column_id = @keycnt_cur and is_included_column = 1
		 
	    set @keycnt_cur += 1
	  end 
	end	

	set @sqlToCreateIndex = @sqlToCreateIndex+
	' with (maxdop=0, SORT_IN_TEMPDB=ON)'+
	case when @filegroup_name is not null then ' ON ['+@filegroup_name+'];'
	else ';' end
	
	set @sqlToDropIndex = 'drop index '+@index+' on '+@schema+'.'+@tbl+';'
	
	print @sqlToDropIndex
	print 'GO'
	print @sqlToCreateIndex
	print 'GO'
	
end

close Idx_crsr
deallocate Idx_crsr
		


