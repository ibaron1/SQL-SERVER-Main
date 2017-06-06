

---- all fkS 

create table #t
(sqlstr varchar(max))

insert #t
exec sp_allFKs
@operation = 'DROP' --generates DROP and ADD FK constraints

select * from #t
where sqlstr like '%DROP%'
order by sqlstr

select * from #t
where sqlstr like '%ADD%'
order by sqlstr

--drop table #t