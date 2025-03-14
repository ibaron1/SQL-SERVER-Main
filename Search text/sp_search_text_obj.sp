USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_search_text_obj]    Script Date: 05/31/2012 18:55:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[sp_search_text_obj] 
@objname varchar(100)=null,
@db varchar(100) = null

as
set nocount on

select @db = isnull(@db, db_name())

declare @search table (searchString varchar(100))
declare @searchString varchar(100)

insert @search 
values ('s2ss.'),
('( null'),
 (' null )'),
 ('WITH (INDEX ('),
('like @'),
('CURSOR%DYNAMIC'),
('CURSOR%STATIC'),
('float('),
('float ('),
 ('nvarchar(max)'),
('set rowcount'),
(' char('),
('(char('),
('left '),
('right '),
('%IS NOT NULL%OR%IS NOT NULL%AND%<>' )

declare searchCrsr cursor read_only fast_forward 
for select searchString from @search

open searchCrsr

while 1=1
begin
	fetch searchCrsr into @searchString
	
	if @@fetch_status <> 0
	  break
	  
	select @searchString
	exec sp_search_text @searchfor=@searchString, @db = @db, @objname = @objname

end

close searchCrsr
deallocate searchCrsr 	



