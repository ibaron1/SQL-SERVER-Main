echo on

rem set DbList=S05DER3_dbs.1db.txt
set DbList=S05DER3_dbs.txt
set rootDir=C:\CompareDatabases\Between2instances
        rem instance with clone dbs
set instance1=gamma2case
set instance1Pwd=Bi75911@
set instance1alias=clone_db_on_S05DER3
       rem instance with source dbs
set instance2=gammacase
set instance2Pwd=Bi75911@
set instance2alias=source_db_on_S01DER3

set diffObjects=%rootDir%\diffObjects
set sameObjects=%rootDir%\sameObjects

SET CYGWIN=nodosfilewarning 

rem if exist %rootDir% (rmdir /s /q %rootDir%)
rem mkdir %rootDir%
if not exist %rootDir% (mkdir %rootDir%)
if not exist c:\tmp\diffsql (mkdir c:\tmp\diffsql)
if not exist %diffObjects% (mkdir %diffObjects%)
if not exist c:\tmp\samesql (mkdir c:\tmp\samesql)
if not exist %sameObjects% (mkdir %sameObjects%)

echo if exists (select 1 from tempdb..sysobjects where name='dbs') > %rootDir%\dbs1.sql
echo drop table tempdb..dbs >> %rootDir%\dbs1.sql
echo go >> %rootDir%\dbs1.sql
echo select name into tempdb..dbs from master..sysdatabases >> %rootDir%\dbs1.sql
echo where name not in ('master','tempdb','model','sybsystemprocs','dbccdb','sybsystemdb') >> %rootDir%\dbs1.sql
echo order by lower(name) >> %rootDir%\dbs1.sql
echo go  >> %rootDir%\dbs1.sql

bcp tempdb..dbs out %rootDir%\dbs1.out -Usa -S%instance1% -P%instance1Pwd% -c

echo if exists (select 1 from tempdb..sysobjects where name='dbList') > %rootDir%\dbs2.sql
echo drop table tempdb..dbList >> %rootDir%\dbs2.sql
echo go  >> %rootDir%\dbs2.sql
echo create table tempdb..dbList(name varchar(30))  >> %rootDir%\dbs2.sql
echo go   >> %rootDir%\dbs2.sql

isql -Usa -S%instance2% -P %instance2Pwd% -i%rootDir%\dbs2.sql
bcp tempdb..dbList in %rootDir%\dbs1.out -Usa -S%instance2% -P %instance2Pwd% -c

echo if exists (select 1 from tempdb..sysobjects where name='sameDbs') > %rootDir%\sameDbs.sql
echo drop table tempdb..sameDbs >> %rootDir%\sameDbs.sql
echo go >> %rootDir%\sameDbs.sql
echo select s.name into tempdb..sameDbs from master..sysdatabases s, tempdb..dbList l >>  %rootDir%\sameDbs.sql
echo where s.name = ltrim(l.name)  >>  %rootDir%\sameDbs.sql
echo order by lower(s.name)  >>  %rootDir%\sameDbs.sql
echo go >>  %rootDir%\sameDbs.sql

isql -Usa -S%instance2% -P %instance2Pwd% -i%rootDir%\sameDbs.sql
bcp tempdb..sameDbs out %rootDir%\sameDbsList.txt -Usa -S%instance2% -P%instance2Pwd% -c

rem for /f %%T in (%rootDir%\sameDbsList.txt) do (CompareOneDbBtwn2instances.cmd %%T %diffObjects% %instance1% %instance1Pwd% %instance2% %instance2Pwd% %sameObjects% %instance1alias% %instance2alias%)

for /f %%T in (%DbList%) do (CompareOneDbBtwn2instances.cmd %%T %diffObjects% %instance1% %instance1Pwd% %instance2% %instance2Pwd% %sameObjects% %instance1alias% %instance2alias%)
