#!/bin/ksh
PATH=/usr/local/sybase/OCS-12_0/bin:/usr/openwin/bin:$PATH
LD_LIBRARY_PATH=/u/sybase/OCS-12_0/lib
SYBASE=/usr/local/sybase
export PATH
export LD_LIBRARY_PATH
export SYBASE
chmod 744 pw
pw=`cat pw`
chmod 000 pw
SRVR_import=GLSRD

isql -Uilyabb -S$SRVR_import -P$pw <<!
if exists (select * from tempdb..sysobjects where name="GPS_tbls")
drop table tempdb..GPS_tbls
go
if exists (select * from tempdb..sysobjects where name="GPS3_tbls")
drop table tempdb..GPS3_tbls
go
if exists (select * from tempdb..sysobjects where name="GPS4_tbls")
drop table tempdb..GPS4_tbls
go
select name=name into tempdb..GPS_tbls from GPS..sysobjects where type='U' and name not in 'rs%'
select name=name into tempdb..GPS3_tbls from GPS3..sysobjects where type='U' and name not in 'rs%'
select name=name into tempdb..GPS4_tbls from GPS4..sysobjects where type='U' and name not in 'rs%'
go
!

bcp tempdb..GPS_tbls out GPS_tbls -Uilyabb -S$SRVR_import -P$pw -c
bcp tempdb..GPS3_tbls out GPS3_tbls -Uilyabb -S$SRVR_import -P$pw -c
bcp tempdb..GPS4_tbls out GPS4_tbls -Uilyabb -S$SRVR_import -P$pw -c

#### save statistics from GPS, GPS3 and GPS4 dbs from importing statistics server

for tbl in `cat GPS_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS..${tbl} -Uilyabb -S$SRVR_import -P$pw -o${SRVR
_import}/GPS_old/${tbl}.opt
done

for tbl in `cat GPS3_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS3..${tbl} -Uilyabb -S$SRVR_import -P$pw -o${SRV
R_import}/GPS3_old/${tbl}.opt
done

for tbl in `cat GPS4_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS4..${tbl} -Uilyabb -S$SRVR_import -P$pw -o${SRV
R_import}/GPS4_old/${tbl}.opt
done

