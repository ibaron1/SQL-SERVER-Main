create table DataToBeSliced
(somename varchar(100))

insert DataToBeSliced
values
('adc')
,('abc')
,('Cdd')
,('Dee')
,('Eaa')

GO
-- To slice number of rows into 2 per group
select --row_number() over (order by somename) , 
row_number() over (order by somename) / 2 + 1 as COUPLEID, somename
from DataToBeSliced
order by COUPLEID, somename
/*COUPLEID	somename
	1	abc
	2	adc
	2	Cdd
	3	Dee
	3	Eaa */

select (row_number() over (order by somename) -1)/ 2 + 1 as COUPLEID, somename
from DataToBeSliced
order by COUPLEID, somename
/*COUPLEID	somename
	1	abc
	1	adc
	2	Cdd
	2	Dee
	3	Eaa */

-- To slice all rows into 2 groups
select ntile(2) over (order by somename) as GroupId, somename
from DataToBeSliced
order by GroupId, somename
/*GroupId	somename
	1	abc
	1	adc
	1	Cdd
	2	Dee
	2	Eaa */