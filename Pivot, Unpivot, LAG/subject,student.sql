/*
HINDI	ENGLISH	MATHS
A		A		C
B		B	 
*/
create table abc
(Student char(1), [Subject] varchar(20)) 
go
insert abc
values
('A','HINDI'),
('A','ENGLISH'),
('A','MATHS'),
('B','HINDI'),
('B','ENGLISH'),
('C','MATHS')
go
select * from ab
--pivot
with cte
select distinct [Subject] from abc
as
(select 