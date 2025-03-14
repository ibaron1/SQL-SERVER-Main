create table a
(city varchar(100),
 country varchar(100),
 population int)

 delete a
 insert a
 values
 ('New York','USA',12000000),
 ('Boston','USA',8000000),
 ('Tijana','Mexico',15000000),
 ('Toronto','Canada',10000000),
 ('Toronto','Canada',10000000)

 ;with cte
 as
 (select city,country,population
,row_number() over (partition by city,country,population order by city,country,population) as row#
from a)
delete from cte where row# > 1

select * from a