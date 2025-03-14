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
SRVR_import=GLSRD

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
select name=name into tempdb..GPS_tbls from GPS..sysobjects where type='U' and name not in 'rs%' and name not in 'sys%'
select name=name into tempdb..GPS3_tbls from GPS3..sysobjects where type='U' and name not in 'rs%' and name not in 'sys%'
select name=name into tempdb..GPS4_tbls from GPS4..sysobjects where type='U' and name not in 'rs%' and name not in 'sys%'
go
!

bcp tempdb..GPS_tbls out GPS_tbls -Uilyabb -S$SRVR_export -P$pw -c
bcp tempdb..GPS3_tbls out GPS3_tbls -Uilyabb -S$SRVR_export -P$pw -c
bcp tempdb..GPS4_tbls out GPS4_tbls -Uilyabb -S$SRVR_export -P$pw -c

#### Import statistics from GPS db on exporting statistics server into GPS, GPS3 and GPS4 dbs on importing stats servers

#### import GPS
for tbl in `cat GPS_tbls`
do
sed "s/$SRVR_export/$SRVR_import/g" < ${SRVR_export}/GPS/${tbl}.opt > tmp
mv tmp ${SRVR_export}/GPS/${tbl}.opt
/glsrd/database/sybase/ASE-12_5/bin/optdiag statistics -i${SRVR_export}/GPS/${tbl}.opt -Uilyabb -S$SRVR_import -P$pw 
done

#### import GPS3
for tbl in `cat GPS3_tbls`
do
sed "s/$SRVR_export/$SRVR_import/g" < ${SRVR_export}/GPS3/${tbl}.opt > tmp
sed "s/GPS/GPS3/g" < tmp > tmp1
mv tmp1 ${SRVR_export}/GPS3/${tbl}.opt
rm tmp
/glsrd/database/sybase/ASE-12_5/bin/optdiag statistics -i${SRVR_export}/GPS3/${tbl}.opt -Uilyabb -S$SRVR_import  -P$pw
done

#### import GPS4
for tbl in `cat GPS4_tbls`
do
sed "s/$SRVR_export/$SRVR_import/g" < ${SRVR_export}/GPS4/${tbl}.opt > tmp
sed "s/GPS/GPS4/g" < tmp > tmp1
mv tmp1 ${SRVR_export}/GPS4/${tbl}.opt
rm tmp
/glsrd/database/sybase/ASE-12_5/bin/optdiag statistics -i${SRVR_export}/GPS4/${tbl}.opt -Uilyabb -S$SRVR_import -P$pw
done
