set nocount on

declare
@operation varchar(10) --ENABLE, DISABLE, DROP, CREATE 

declare @schema varchar(20), @tbl varchar(100), 
@PKconstraint varchar(100), @clmn varchar(100), @is_unique int, @PKconstraint_id int
declare @keycnt_cur int, @keycnt int, @schema_tblname varchar(100),
@sqlToDropPK varchar(400), @sqlToAddPK varchar(400), @object_id int, 
@filegroup_name varchar(200)

declare
PK_crsr cursor fast_forward forward_only for 
	SELECT SCHEMA_NAME(o.schema_id) as [schema],
	o.name as [Table], o.object_id, i.name as PKconstraint,i.index_id,--= 1  - clustered, > 1 - nonclustered
	i.is_unique -- 1 - unique, 0 - not unique
	from sys.objects o join sys.indexes i
	on o.object_id = i.object_id and o.type = 'U'
	where is_primary_key = 1

open PK_crsr

while 1 = 1
  begin 
	fetch PK_crsr into @schema, @tbl, @object_id, @PKconstraint, @PKconstraint_id, @is_unique
	
	if @@FETCH_STATUS <> 0
		break
		
	select @filegroup_name = 
	(select top(1) f.name
	 from sys.filegroups f join sys.indexes i
	 on f.data_space_id = i.data_space_id
	 where i.object_id = @object_id and i.name = @PKconstraint)
		
	-- Generate sql to recreate PK 
	
	select @keycnt = COUNT(*)
	from sys.index_columns
	where object_id = @object_id and index_id = @PKconstraint_id
	
	select @keycnt_cur = 1 , @schema_tblname = @schema+'.'+@tbl
	
	select @sqlToAddPK =
		     'ALTER TABLE '+@schema_tblname+' ADD PRIMARY KEY '+
		       case @PKconstraint_id when 1 then 'CLUSTERED'
					     else 'NONCLUSTERED' end+' ('	

	while @keycnt_cur <= @keycnt
	begin
		select @sqlToAddPK = @sqlToAddPK+
		c.name+case is_descending_key
				when 0 then ' asc' else ' desc' end+
		 case when @keycnt_cur < @keycnt then ',' else ')' end 
		from sys.index_columns ic
		join sys.columns c
		on ic.object_id  = c.object_id
		and c.object_id = @object_id
		and ic.index_id = @PKconstraint_id
		and ic.column_id = c.column_id 
		where index_column_id = @keycnt_cur
		 		 		 
		set @keycnt_cur = @keycnt_cur+1
	end

	set @sqlToAddPK = @sqlToAddPK+
	' with (MAXDOP=0, SORT_IN_TEMPDB=ON)'+
	case when @filegroup_name is not null then ' ON ['+@filegroup_name+'];'
	else ';' end

	set @sqlToDropPK = 'ALTER TABLE '+@schema+'.'+@tbl+' DROP CONSTRAINT '+@PKconstraint+';'
	
	print @sqlToDropPK
	print 'GO'
	print @sqlToAddPK
	print 'GO'
	
end

close PK_crsr
deallocate PK_crsr
