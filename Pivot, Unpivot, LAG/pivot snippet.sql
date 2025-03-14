set nocount on;
drop table if exists  #abc;
create table #abc
(Student char(1), [Subject] varchar(20)) 
go
insert #abc
values
('A','HINDI'),('A','ENGLISH'),('A','MATHS'),('B','HINDI'),('B','ENGLISH'),('C','MATHS');


SELECT Student, 'ENGLISH','HINDI','MATHS' from 
            (
                select Student
					 ,[Subject]
                from #abc
           ) x
            pivot 
            (
                 max(Student)
                for [Subject] in (ENGLISH,HINDI,MATHS)
            ) p 

/*
HINDI	ENGLISH	MATHS
A		A		C
B		B	 
*/
DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX);

SET @cols =  STUFF((SELECT distinct ',' + ''''+[Subject]+''''
            FROM #abc
            for xml path('')
				)
				,1,1,'')

select @cols as 'Columns'

set @query = 'SELECT Student, ' + @cols + ' from 
            (
                select Student
					 ,[Subject]
                from #abc
           ) x
            pivot 
            (
                 max(Student)
                for Subject in (' + @cols + ')
            ) p '
print @query
execute(@query)