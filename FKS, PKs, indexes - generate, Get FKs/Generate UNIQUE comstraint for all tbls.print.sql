SET NOCOUNT ON  

declare
@operation varchar(10) --DROP, CREATE 
 
set @operation = 'CREATE'

declare @schema varchar(20), @tbl varchar(100), 
@UniqueConst varchar(100), @clmn varchar(100), @is_unique int, @PKconstraint_id int
declare @keycnt_cur int, @keycnt int, @schema_tblname varchar(100),
@sqlToDropUQ varchar(400), @sqlToAddUQ varchar(400), @object_id int, @parent_object_id int,
@filegroup_name varchar(200) 

DECLARE @cmd nvarchar(1000) 

declare
UQ_crsr cursor fast_forward forward_only for
	select schema_name(schema_id), OBJECT_NAME(parent_object_id) as tbl, name as UniqueConst 
	from sys.objects
	where type='UQ'

open UQ_crsr

while 1 = 1
  begin 
	fetch UQ_crsr into @schema, @tbl, @UniqueConst
	
	if @@FETCH_STATUS <> 0
		break

	IF @operation = 'DROP'
        BEGIN 
      	        set @sqlToDropUQ = 'ALTER TABLE '+@schema+'.'+@tbl+' DROP CONSTRAINT '+@UniqueConst+';'
	
		print @sqlToDropUQ
		print 'GO'
		
		CONTINUE
	  END
	
	select @filegroup_name = 
	(select top (1) FILEGROUP_NAME(i.data_space_id) 
	from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE u
	join sys.indexes i
	on object_id(u.TABLE_SCHEMA+'.'+u.TABLE_NAME)= i.object_id
	where CONSTRAINT_NAME = @UniqueConst)	
 
	-- Generate sql to recreate UQ

 	select @keycnt = COUNT(*)
	from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE u
	where CONSTRAINT_NAME = @UniqueConst

	select @keycnt_cur = 1 , @schema_tblname = @schema+'.'+@tbl

	select @sqlToAddUQ =
		     'ALTER TABLE '+@schema_tblname+' ADD CONSTRAINT '+QUOTENAME(@UniqueConst)+' UNIQUE '+
		       case @PKconstraint_id when 1 then 'CLUSTERED'
					     else 'NONCLUSTERED' end+' ('

	while @keycnt_cur <= @keycnt
	begin

		WITH CTE_clmn AS
		(	
			select ROW_NUMBER() OVER (ORDER BY COLUMN_NAME) AS RowNumber
			,u.COLUMN_NAME, (u.TABLE_SCHEMA+'.'+u.TABLE_NAME) as schema_tbl
			from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE u
			where CONSTRAINT_NAME = @UniqueConst
		) 
		select @sqlToAddUQ = @sqlToAddUQ+COLUMN_NAME+
		   case when @keycnt_cur < @keycnt then ',' else ')' end
		from CTE_clmn 
		where RowNumber = @keycnt_cur
		 		 
		set @keycnt_cur = @keycnt_cur+1
	end

	set @sqlToAddUQ = @sqlToAddUQ+
	' with (MAXDOP=0, SORT_IN_TEMPDB=ON)'+
	case when @filegroup_name is not null then ' ON ['+@filegroup_name+'];'
	else ';' end

	print @sqlToAddUQ
	print 'GO'
	
end

close UQ_crsr
deallocate UQ_crsr

GO



