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
 ('Toronto','Canada',10000000)

;with cte
as
(select country,max(population) as max_population
from a
group by country)
select * from a
join cte
on a.country = cte.country
and a.population = cte.max_population
--or
select * from a
join
(select country,max(population) as max_population
from a
group by country) b
on a.country = b.country
and a.population = b.max_population
