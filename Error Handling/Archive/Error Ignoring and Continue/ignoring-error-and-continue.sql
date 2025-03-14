--https://www.sqlservercentral.com/forums/topic/ignoring-error-and-continue

drop table if exists dbo.test_t;
go
create table dbo.test_t(x           int not null);
go

drop proc if exists dbo.test_proc_a;
go
create proc dbo.test_proc_a
as
set nocount on;
set xact_abort on;

begin transaction
begin try
    declare
      @output_bit           bit,
      @output_msg           nvarchar(max);

    exec dbo.test_proc_b N'dbo.test_t', @result_bit=@output_bit output, @result_msg=@output_msg output;
    print (cast(@output_bit as nchar(1)));
    print (cast(@output_msg as nvarchar(max)));
    print ('xact_state='+cast(xact_state() as nvarchar(3)));

    if (xact_state()=-1)
        begin
            rollback transaction;
            begin transaction;
        end

    exec dbo.test_proc_b N'pdq', @result_bit=@output_bit output, @result_msg=@output_msg output;
    print (cast(@output_bit as nchar(1)));
    print (cast(@output_msg as nvarchar(max)));
    print ('xact_state='+cast(xact_state() as nvarchar(3)));

    if (xact_state()=-1)
        begin
            rollback transaction;
            begin transaction;
        end

    exec dbo.test_proc_b N'dbo.test_t', @result_bit=@output_bit output, @result_msg=@output_msg output;
    print (cast(@output_bit as nchar(1)));
    print (cast(@output_msg as nvarchar(max)));
    print ('xact_state='+cast(xact_state() as nvarchar(3)));

    if (xact_state()=-1)
        begin
            rollback transaction;
        end

    if (@@trancount>0)
        commit transaction;
end try
begin catch
    print (error_message());
    
    rollback transaction;
end catch
go

drop proc if exists dbo.test_proc_b;
go
create proc dbo.test_proc_b
  @sys_table_name         nvarchar(256),
  @result_bit             bit output,
  @result_msg             nvarchar(max) output
as
set nocount on;
begin try
    /* test to make sure the table exists */
    --if (object_id(@sys_table_name, 'U') is null)
    --    throw 50000, 'The table does not exist', 1;
    if (object_id('dbo.test_t', 'U') is null)
        throw 50000, 'The table does not exist', 1;

    /* 1) do something that works */
    --insert dbo.test_t(x) values(1);

    /* 2) create an exception on purpose divide by zero and return system error message*/
    insert dbo.test_t(x) values(4/0);

    /* 3) create an exception on purpose using THROW */
    declare @error_msg      nvarchar(max)=concat(N'test_proc_b input @sys_table_name=', @sys_table_name);
    throw 50000, @error_msg, 1;

    select @result_bit=cast(1 as bit);
    select @result_msg=N'Ok';
end try
begin catch
    select @result_bit=cast(0 as bit);
    select @result_msg=error_message();
end catch
go

/*
exec dbo.test_proc_a;

declare  @result_bit             bit ,
  @result_msg             nvarchar(max) 

exec dbo.test_proc_b sys_table_name = 'dbo.test_t',
  @result_bit = result_bit output,
  @result_msg = result_msg output


Results

0
test_proc_b input @sys_table_name=dbo.test_t
0
test_proc_b input @sys_table_name=pdq
0
test_proc_b input @sys_table_name=dbo.test_t
*/