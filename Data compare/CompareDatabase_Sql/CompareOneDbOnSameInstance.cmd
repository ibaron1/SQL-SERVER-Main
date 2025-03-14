echo on

echo set nocount on  > c:\tmp\diffsql\%1.sql
echo select name into #t1 from %1..sysobjects c  >> c:\tmp\diffsql\%1.sql
echo where type='U' and not exists  >> c:\tmp\diffsql\%1.sql
echo (select '1' from %2..sysobjects where type='U' and name=c.name)  >> c:\tmp\diffsql\%1.sql
echo if @@rowcount != 0   >> c:\tmp\diffsql\%1.sql
echo   select ' ' as '%8 instance', name as  'extra tables' from #t1 >> c:\tmp\diffsql\%1.sql
echo select ' ' >> c:\tmp\diffsql\%1.sql

echo select name into #t2 from %2..sysobjects  c   >>c:\tmp\diffsql\%1.sql
echo where type='U' and not exists  >> c:\tmp\diffsql\%1.sql
echo (select '1' from %1..sysobjects where type='U' and name=c.name)  >> c:\tmp\diffsql\%1.sql
echo if @@rowcount != 0   >> c:\tmp\diffsql\%1.sql
echo   select ' ' as '%7 instance', name as  'extra tables' from #t2 >> c:\tmp\diffsql\%1.sql
echo select ' ' >> c:\tmp\diffsql\%1.sql

echo select name into #p1 from %1..sysobjects c  >> c:\tmp\diffsql\%1.sql
echo where type='P' and not exists  >> c:\tmp\diffsql\%1.sql
echo (select '1' from %2..sysobjects where type='P' and name=c.name)  >> c:\tmp\diffsql\%1.sql
echo if @@rowcount != 0   >> c:\tmp\diffsql\%1.sql
echo   select ' ' as '%8 instance', name as  'extra procs'  from #p1 >> c:\tmp\diffsql\%1.sql
echo select ' ' >> c:\tmp\diffsql\%1.sql

echo select name into #p2 from %2..sysobjects  c   >> c:\tmp\diffsql\%1.sql
echo where type='P' and not exists  >> c:\tmp\diffsql\%1.sql
echo (select '1' from %1..sysobjects where type='P' and name=c.name)  >> c:\tmp\diffsql\%1.sql
echo if @@rowcount != 0   >> c:\tmp\diffsql\%1.sql
echo   select ' ' as '%7 instance', name as  'extra procs' from #p2 >> c:\tmp\diffsql\%1.sql
echo select ' ' >> c:\tmp\diffsql\%1.sql

echo select name into #v1 from %1..sysobjects c  >> c:\tmp\diffsql\%1.sql
echo where type='V' and not exists  >> c:\tmp\diffsql\%1.sql
echo (select '1' from %2..sysobjects where type='V' and name=c.name)  >> c:\tmp\diffsql\%1.sql
echo if @@rowcount != 0   >> c:\tmp\diffsql\%1.sql
echo   select ' ' as '%8 instance', name as  'extra views'  from #v1 >> c:\tmp\diffsql\%1.sql
echo select ' ' >> c:\tmp\diffsql\%1.sql

echo select name into #v2 from %2..sysobjects c   >> c:\tmp\diffsql\%1.sql
echo where type='V' and not exists  >> c:\tmp\diffsql\%1.sql
echo (select '1' from %1..sysobjects where type='V' and name=c.name)  >>c:\tmp\diffsql\%1.sql
echo if @@rowcount != 0   >> c:\tmp\diffsql\%1.sql
echo   select ' ' as '%7 instance', name as  'extra views' from #v2 >> c:\tmp\diffsql\%1.sql
echo select ' ' >> c:\tmp\diffsql\%1.sql

echo select name into #tr1 from %1..sysobjects c  >> c:\tmp\diffsql\%1.sql
echo where type='TR' and not exists  >> c:\tmp\diffsql\%1.sql
echo (select '1' from %2..sysobjects where type='TR' and name=c.name)  >> c:\tmp\diffsql\%1.sql
echo if @@rowcount != 0   >> c:\tmp\diffsql\%1.sql
echo   select ' ' as '%8 instance', name as  'extra triggers' from #tr1 >> c:\tmp\diffsql\%1.sql
echo select ' ' >> c:\tmp\diffsql\%1.sql

echo select name into #tr2 from %2..sysobjects  c   >> c:\tmp\diffsql\%1.sql
echo where type='TR' and not exists  >> c:\tmp\diffsql\%1.sql
echo (select '1' from %1..sysobjects where type='TR' and name=c.name)  >> c:\tmp\diffsql\%1.sql
echo if @@rowcount != 0   >> c:\tmp\diffsql\%1.sql
echo   select ' ' as '%7 instance', name as  'extra triggers' from #tr2 >> c:\tmp\diffsql\%1.sql

echo drop table #t1,#t2,#p1,#p2,#v1,#v2,#tr1,#tr2 >> c:\tmp\diffsql\%1.sql
echo go  >> c:\tmp\diffsql\%1.sql

isql -Usa -S%4 -P%5 -ic:\tmp\diffsql\%1.sql -o%3\%1.out

if not exist %6\%1 (mkdir %6\%1)

echo set nocount on > c:\tmp\samesql\%1.sql
echo select c.name from %1..sysobjects c join %2..sysobjects d>> c:\tmp\samesql\%1.sql
echo on c.name=d.name and c.type='P' and d.type='P' >> c:\tmp\samesql\%1.sql
echo go  >> c:\tmp\samesql\%1.sql

isql -b -Usa -S%4 -P%5 -ic:\tmp\samesql\%1.sql -o%6\%1\procs.txt

if not exist %6\%1\procs (mkdir %6\%1\procs)
if not exist %6\%1\procs\_CompareResults (mkdir %6\%1\procs\_CompareResults)
if not exist %6\%1\procs\%7 (mkdir %6\%1\procs\%7)
if not exist %6\%1\procs\%8 (mkdir %6\%1\procs\%8)

for /f %%T in (%6\%1\procs.txt) do (defncopy -Usa -S%4 -P%5 out %6\%1\procs\%7\%%T.sql %1 %%T & defncopy -Usa -S%4 -P%5 out %6\%1\procs\%8\%%T.sql %1 %%T & diff -i -w -E %6\%1\procs\%7\%%T.sql %6\%1\procs\%8\%%T.sql > %6\%1\procs\_CompareResults\%%T.txt)

echo set nocount on > c:\tmp\samesql\%1.sql
echo select c.name from %1..sysobjects c join %2..sysobjects d>> c:\tmp\samesql\%1.sql
echo on c.name=d.name and c.type='V' and d.type='V' and  ltrim(rtrim(d.name)) != 'sysquerymetrics'  >> c:\tmp\samesql\%1.sql
echo go  >> c:\tmp\samesql\%1.sql

isql -b -Usa -S%4 -P%5 -ic:\tmp\samesql\%1.sql -o%6\%1\views.txt

if not exist %6\%1\views (mkdir %6\%1\views)
if not exist %6\%1\views\_CompareResults (mkdir %6\%1\views\_CompareResults)
if not exist %6\%1\views\%7 (mkdir %6\%1\views\%7)
if not exist %6\%1\views\%8 (mkdir %6\%1\views\%8)

for /f %%T in (%6\%1\views.txt) do (defncopy -Usa -S%4 -P%5 out %6\%1\views\%7\%%T.sql %1 %%T & defncopy -Usa -S%4 -P%5 out %6\%1\views\%8\%%T.sql %1 %%T & diff -i -w -E %6\%1\views\%7\%%T.sql %6\%1\views\%8\%%T.sql > %6\%1\views\_CompareResults\%%T.txt)

echo set nocount on > c:\tmp\samesql\%1.sql
echo select c.name from %1..sysobjects c join %2..sysobjects d>> c:\tmp\samesql\%1.sql
echo on c.name=d.name and c.type='TR' and d.type='TR' >> c:\tmp\samesql\%1.sql
echo go  >> c:\tmp\samesql\%1.sql

isql -b -Usa -S%4 -P%5 -ic:\tmp\samesql\%1.sql -o%6\%1\triggers.txt

if not exist %6\%1\triggers (mkdir %6\%1\triggers)
if not exist %6\%1\triggers\_CompareResults (mkdir %6\%1\triggers\_CompareResults)
if not exist %6\%1\triggers\%7 (mkdir %6\%1\triggers\%7)
if not exist %6\%1\triggers\%8 (mkdir %6\%1\triggers\%8)

for /f %%T in (%6\%1\triggers.txt) do (defncopy -Usa -S%4 -P%5 out %6\%1\triggers\%7\%%T.sql %1 %%T & defncopy -Usa -S%4 -P%5 out %6\%1\triggers\%8\%%T.sql %1 %%T & diff -i -w -E %6\%1\triggers\%7\%%T.sql %6\%1\triggers\%8\%%T.sql > %6\%1\triggers\_CompareResults\%%T.txt)


