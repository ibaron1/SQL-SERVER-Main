echo on

set sourceDb=deriv_cost_1
set DbList=S01DER3_deriv_cost_1.clone_dbs.txt
set rootDir=C:\CompareDatabases\OnSameInstance
set instance=gammacase
set instanceAlias=S01DER3
set instancePwd=Bi75911@
set cloneDBalias=clone_db_on_%instanceAlias%
set sourceDBalias=source_db_on_%instanceAlias%

set diffObjects=%rootDir%\diffObjects
set sameObjects=%rootDir%\sameObjects

SET CYGWIN=nodosfilewarning 

if not exist %rootDir% (mkdir %rootDir%)
if not exist c:\tmp\diffsql (mkdir c:\tmp\diffsql)
if not exist %diffObjects% (mkdir %diffObjects%)
if not exist c:\tmp\samesql (mkdir c:\tmp\samesql)
if not exist %sameObjects% (mkdir %sameObjects%)


for /f %%T in (%DbList%) do (CompareOneDbOnSameInstance.cmd %%T %sourceDb% %diffObjects% %instance% %instancePwd% %sameObjects% %cloneDBalias% %sourceDBalias%)
