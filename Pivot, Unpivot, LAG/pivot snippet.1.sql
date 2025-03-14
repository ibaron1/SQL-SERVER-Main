
drop table  if exists #OrderTable;
create table #OrderTable
(
    OrderDate datetime,
    Category Varchar(40),
    TotalOrder Int
)

insert into #OrderTable values ('2022/01/12', 'A', 300)
insert into #OrderTable values ('2020/01/21', 'B', 800)
insert into #OrderTable values ('2021/01/21', 'C', 600)
insert into #OrderTable values ('2023/01/21', 'D', 300)
insert into #OrderTable values ('2023/01/21', 'E', 400)

DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX);


SET @cols = STUFF((SELECT distinct ',' + QUOTENAME(Year(OrderDate)) 
            FROM #OrderTable c
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

select @cols as 'Columns'


set @query = 'SELECT Category, ' + @cols + ' from 
            (
                select Year(OrderDate) as YearOrder
                    , TotalOrder
                    , category
                from #OrderTable
           ) x
            pivot 
            (
                 sum(TotalOrder)
                for YearOrder in (' + @cols + ')
            ) p '

execute(@query)

drop table #OrderTable