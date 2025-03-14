echo on

echo select name,type  > %2\%1.sql
echo into tempdb..%1   >> %2\%1.sql
echo from %1..sysobjects  >> %2\%1.sql
echo where type in ('V','P','TR')  >> %2\%1.sql
echo order by type,name  >>%2\ %1.sql
echo go  >> %2\%1.sql

isql -Usa -S%4 -P%5 -i%2\ %1.sql -o%2\%1.out

bcp tempdb..%1 out %2\%1.bcp -Usa -S%4 -P%5 -c

echo if exists (select 1 from tempdb..sysobjects where name='%1') > %2\%1.drop.sql
echo drop table tempdb..%1 >> %2\%1.drop.sql
echo go >> %2\%1.drop.sql
echo select name,type  >> %2\%1.drop.sql
echo into tempdb..%1   >> %2\%1.drop.sql
echo from tempdb..sysobjects where 1=2  >> %2\%1.drop.sql
echo go  >> %2\%1.drop.sql

isql -Usa -S%6 -P%7 -i%2\%1.drop.sql -o%2\%1.drop.out

bcp tempdb..%1 in  %2\%1.bcp -Usa -S%6 -P%7 -c

echo set nocount on  > %2\%1.sql
echo select name into #t1 from %1..sysobjects c  >> %2\%1.sql
echo where type='U' and not exists  >> %2\%1.sql
echo (select '1' from tempdb..%1 where type='U' and name=c.name)  >> %2\%1.sql
echo if @@rowcount != 0   >> %2\%1.sql
echo   select ' ' as '%6 instance', name as  'extra tables' from #t1 >> %2\%1.sql
echo select ' ' >> %2\%1.sql

echo select name into #t2 from tempdb..%1  c   >>%2\%1.sql
echo where type='U' and not exists  >> %2\%1.sql
echo (select '1' from %1..sysobjects where type='U' and name=c.name)  >> %2\%1.sql
echo if @@rowcount != 0   >> %2\%1.sql
echo   select ' ' as '%4 instance', name as  'extra tables' from #t2 >> %2\%1.sql
echo select ' ' >> %2\%1.sql

echo select name into #p1 from %1..sysobjects c  >> %2\%1.sql
echo where type='P' and not exists  >> %2\%1.sql
echo (select '1' from tempdb..%1 where type='P' and name=c.name)  >> %2\%1.sql
echo if @@rowcount != 0   >> %2\%1.sql
echo   select ' ' as '%6 instance', name as  'extra procs'  from #p1 >> %2\%1.sql
echo select ' ' >> %2\%1.sql

echo select name into #p2 from tempdb..%1  c   >> %2\%1.sql
echo where type='P' and not exists  >> %2\%1.sql
echo (select '1' from %1..sysobjects where type='P' and name=c.name)  >> %2\%1.sql
echo if @@rowcount != 0   >> %2\%1.sql
echo   select ' ' as '%4 instance', name as  'extra procs' from #p2 >> %2\%1.sql
echo select ' ' >> %2\%1.sql

echo select name into #v1 from %1..sysobjects c  >> %2\%1.sql
echo where type='V' and not exists  >> %2\%1.sql
echo (select '1' from tempdb..%1 where type='V' and name=c.name)  >> %2\%1.sql
echo if @@rowcount != 0   >> %2\%1.sql
echo   select ' ' as '%6 instance', name as  'extra views'  from #v1 >> %2\%1.sql
echo select ' ' >> %2\%1.sql

echo select name into #v2 from tempdb..%1  c   >> %2\%1.sql
echo where type='V' and not exists  >> %2\%1.sql
echo (select '1' from %1..sysobjects where type='V' and name=c.name)  >>%2\%1.sql
echo if @@rowcount != 0   >> %2\%1.sql
echo   select ' ' as '%4 instance', name as  'extra views' from #v2 >> %2\%1.sql
echo select ' ' >> %2\%1.sql

echo select name into #tr1 from %1..sysobjects c  >> %2\%1.sql
echo where type='TR' and not exists  >> %2\%1.sql
echo (select '1' from tempdb..%1 where type='TR' and name=c.name)  >> %2\%1.sql
echo if @@rowcount != 0   >> %2\%1.sql
echo   select ' ' as '%6 instance', name as  'extra triggers' from #tr1 >> %2\%1.sql
echo select ' ' >> %2\%1.sql

echo select name into #tr2 from tempdb..%1  c   >> %2\%1.sql
echo where type='TR' and not exists  >> %2\%1.sql
echo (select '1' from %1..sysobjects where type='TR' and name=c.name)  >> %2\%1.sql
echo if @@rowcount != 0   >> %2\%1.sql
echo   select ' ' as '%4 instance', name as  'extra triggers' from #tr2 >> %2\%1.sql

echo drop table #t1,#t2,#p1,#p2,#v1,#v2,#tr1,#tr2 >> %2\%1.sql
echo go  >> %2\%1.sql

isql -Usa -S%6 -P%7 -i%2\%1.sql -o%3\%1.out

mkdir %9\%1

echo set nocount on > %8\%1.sql
echo select c.name from %1..sysobjects c join tempdb..%1 d>> %8\%1.sql
echo on c.name=d.name and c.type='P' and d.type='P' >> %8\%1.sql
echo go  >> %8\%1.sql

isql -b -Usa -S%6 -P%7 -i%8\%1.sql -o%9\%1\procs.txt

mkdir %9\%1\procs
mkdir %9\%1\procs\compareResults
mkdir %9\%1\procs\%4
mkdir %9\%1\procs\%6

for /f %%T in (%9\%1\procs.txt) do (defncopy -Usa -S%4 -P%5 out %9\%1\procs\%4\%%T.sql %1 %%T & defncopy -Usa -S%6 -P%7 out %9\%1\procs\%6\%%T.sql %1 %%T & diff -i -w -E %9\%1\procs\%4\%%T.sql %9\%1\procs\%6\%%T.sql > %9\%1\procs\compareResults\%%T.txt)

echo set nocount on > %8\%1.sql
echo select c.name from %1..sysobjects c join tempdb..%1 d>> %8\%1.sql
echo on c.name=d.name and c.type='V' and d.type='V' and  ltrim(rtrim(d.name)) != 'sysquerymetrics'  >> %8\%1.sql
echo go  >> %8\%1.sql

isql -b -Usa -S%6 -P%7 -i%8\%1.sql -o%9\%1\views.txt

mkdir %9\%1\views
mkdir %9\%1\views\compareResults
mkdir %9\%1\views\%4
mkdir %9\%1\views\%6

for /f %%T in (%9\%1\views.txt) do (defncopy -Usa -S%4 -P%5 out %9\%1\views\%4\%%T.sql %1 %%T & defncopy -Usa -S%6 -P%7 out %9\%1\views\%6\%%T.sql %1 %%T & diff -i -w -E %9\%1\views\%4\%%T.sql %9\%1\views\%6\%%T.sql > %9\%1\views\compareResults\%%T.txt)

echo set nocount on > %8\%1.sql
echo select c.name from %1..sysobjects c join tempdb..%1 d>> %8\%1.sql
echo on c.name=d.name and c.type='TR' and d.type='TR' >> %8\%1.sql
echo go  >> %8\%1.sql

isql -b -Usa -S%6 -P%7 -i%8\%1.sql -o%9\%1\triggers.txt

mkdir %9\%1\triggers
mkdir %9\%1\triggers\compareResults
mkdir %9\%1\triggers\%4
mkdir %9\%1\triggers\%6

for /f %%T in (%9\%1\triggers.txt) do (defncopy -Usa -S%4 -P%5 out %9\%1\triggers\%4\%%T.sql %1 %%T & defncopy -Usa -S%6 -P%7 out %9\%1\triggers\%6\%%T.sql %1 %%T & diff -i -w -E %9\%1\triggers\%4\%%T.sql %9\%1\triggers\%6\%%T.sql > %9\%1\triggers\compareResults\%%T.txt)


