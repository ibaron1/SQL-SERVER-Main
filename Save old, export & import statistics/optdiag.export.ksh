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
SRVR_export=GLSR2

isql -Uilyabb -S$SRVR_export -P$pw << !
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

bcp tempdb..GPS_tbls out GPS_tbls -Uilyabb -S$SRVR_export -P$pw -c
bcp tempdb..GPS3_tbls out GPS3_tbls -Uilyabb -S$SRVR_export -P$pw -c
bcp tempdb..GPS4_tbls out GPS4_tbls -Uilyabb -S$SRVR_export -P$pw -c

#### export statistics from GPS db on export server for import into GPS, GPS3 and GPS4 dbs on importing statistics server

if [[ -d ${SRVR_export}/GPS ]];then
  rm -r ${SRVR_export}/GPS
ficd 
mkdir ${SRVR_export}/GPS

for tbl in `cat GPS_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS..${tbl} -Uilyabb -S$SRVR_export -P$pw -o${SRVR_export}/GPS/${tbl}.opt
done

if [[ -d ${SRVR_export}/GPS3 ]];then
  rm -r ${SRVR_export}/GPS3
fi
mkdir ${SRVR_export}/GPS3

for tbl in `cat GPS3_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS..${tbl} -Uilyabb -S$SRVR_export -P$pw -o${SRVR_export}/GPS3/${tbl}.opt
done

if [[ -d ${SRVR_export}/GPS4 ]];then
  rm -r ${SRVR_export}/GPS4
fi
mkdir ${SRVR_export}/GPS4

for tbl in `cat GPS4_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS..${tbl} -Uilyabb -S$SRVR_export -P$pw -o${SRVR_export}/GPS4/${tbl}.opt
done
