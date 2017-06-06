

set nocount on

declare @schema varchar(20), @tbl varchar(100), @index varchar(100), @clmn varchar(100), @is_unique int, @index_id int
declare @PKtblConstr varchar(100)
declare @keycnt_cur int, @keycnt int, @tblind varchar(100), @sqlToDropIndex varchar(400), @sqlToCreateIndexOrPK varchar(400)
declare @dt datetime

DECLARE
Idx_crsr CURSOR LOCAL FORWARD_ONLY DYNAMIC FOR 
		SELECT distinct user_name(o.uid) as [schema], o.name as [Table], i.name as Idx, 
			i.is_unique, -- 1 - unique, 0 - not unique
			i.index_id  -- = 1 - clustered, > 1 - nonclustered
			,kc.name as PKtblConstr
		FROM sys.columns c JOIN sys.types t
		ON t.user_type_id = c.user_type_id
		JOIN sysobjects o
		ON c.object_id = o.id and o.type = 'U'
		JOIN sys.indexes i 
		ON o.id = i.object_id		
		LEFT JOIN sys.key_constraints kc
		ON i.object_id = kc.parent_object_id
		and i.index_id = kc.unique_index_id	

   OPEN Idx_crsr
   
   WHILE 1 = 1
   	BEGIN

  		 FETCH Idx_crsr INTO @schema, @tbl, @index, @is_unique, @index_id, @PKtblConstr
 
  		 IF @@FETCH_STATUS <> 0
      		      BREAK

		-- Generate sql for clustered index to recreate it after a column from index was modified

		     SELECT @keycnt = count(*) 
		     FROM sys.index_columns
		     WHERE object_name(object_id) = @tbl and index_id = @index_id

		     SELECT @keycnt_cur = 1, @tblind =  @schema+'.'+@tbl

		IF @PKtblConstr is null
		     SELECT @sqlToCreateIndexOrPK = 
		     ' create '+case @is_unique when 1 then 'unique' when 0 then ' ' end+
		     case when @index_id  = 1 then ' clustered ' when @index_id > 1 then ' nonclustered ' end+
		      'index '+@index+' on '+@schema+'.'+@tbl+'('
		ELSE
		BEGIN
		      SELECT @sqlToCreateIndexOrPK =
		     ' ALTER TABLE '+@tblind+' ADD PRIMARY KEY ('


		END

		     WHILE @keycnt_cur <= @keycnt
		     BEGIN   
		         SELECT @sqlToCreateIndexOrPK = @sqlToCreateIndexOrPK+
			index_col(@tblind, @index_id, @keycnt_cur)+
			(select case is_descending_key 
              				when 0 then ' asc' when 1 then ' desc' end 
				 from sys.index_columns 
 			where object_name(object_id) = @tbl and index_id = @index_id and index_column_id = @keycnt_cur)+
			case when @keycnt_cur < @keycnt then ',' else ')' end 
		         
		         SET @keycnt_cur = @keycnt_cur+1
		     END

		     IF @PKtblConstr is null
			BEGIN
			     SET @sqlToCreateIndexOrPK = @sqlToCreateIndexOrPK+' with (maxdop=0, SORT_IN_TEMPDB=ON);'
			     SET @sqlToDropIndex = 'drop index '+@index+' on '+@schema+'.'+@tbl+';'
			END
		     ELSE
			BEGIN
			     SET @sqlToCreateIndexOrPK = @sqlToCreateIndexOrPK+';'
			     SET @sqlToDropIndex = 'ALTER TABLE '+@schema+'.'+@tbl+' DROP CONSTRAINT '+@PKtblConstr+';'	
			END
	     

			print @sqlToCreateIndexOrPK
			print 'GO'

	END

   CLOSE Idx_crsr
   DEALLOCATE Idx_crsr


