#!/bin/ksh
chmod 744 pw
pw=`cat pw`
chmod 000 pw
SRVR_export=GLSR2
SRVR_import=GLSRD

isql -Uilyabb -S$SRVR_export -P$pw << EOF
if exists (select * from tempdb..sysobjects where name="GPS_tbls")
drop table tempdb..GPS_tbls
go
if exists (select * from tempdb..sysobjects where name="GPS3_tbls")
drop table tempdb..GPS3_tbls
go
if exists (select * from tempdb..sysobjects where name="GPS4_tbls")
drop table tempdb..GPS4_tbls
go
select name=name into tempdb..GPS_tbls from GPS..sysobjects where type='U'
select name=name into tempdb..GPS3_tbls from GPS3..sysobjects where type='U'
select name=name into tempdb..GPS4_tbls from GPS4..sysobjects where type='U'
go
EOF

bcp tempdb..GPS_tbls out GPS_tbls -Uilyabb -S$SRVR_export -P$pw -c
bcp tempdb..GPS3_tbls out GPS3_tbls -Uilyabb -S$SRVR_export -P$pw -c
bcp tempdb..GPS4_tbls out GPS4_tbls -Uilyabb -S$SRVR_export -P$pw -c

#### save statistics from GPS, GPS3 and GPS4 dbs from importing statistics server

for tbl in `cat GPS_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS..${tbl} -Uilyabb -S$SRVR_import -P$pw -o${SRVR_import}/GPS_old/${tbl}.opt
done

for tbl in `cat GPS3_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS3..${tbl} -Uilyabb -S$SRVR_import -P$pw -o${SRVR_import}/GPS3_old/${tbl}.opt
done

for tbl in `cat GPS4_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS4..${tbl} -Uilyabb -S$SRVR_import -P$pw -o${SRVR_import}/GPS4_old/${tbl}.opt
done

#### export statistics from GPS db on export server for import into GPS, GPS3 and GPS4 dbs on importing statistics server

for tbl in `cat GPS_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS..${tbl} -Uilyabb -S$SRVR_export -P$pw -o${SRVR_export}/GPS/${tbl}.opt
done


for tbl in `cat GPS3_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS..${tbl} -Uilyabb -S$SRVR_export -P$pw -o${SRVR_export}/GPS3/${tbl}.opt
done

for tbl in `cat GPS4_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag binary statistics GPS..${tbl} -Uilyabb -S$SRVR_export -P$pw -o${SRVR_export}/GPS4/${tbl}.opt
done

#### Import statistics from GPS db on exporting statistics server into GPS, GPS3 and GPS4 dbs on impoering stats servers

for tbl in `cat GPS_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag statistics -i${SRVR_export}/GPS/${tbl}.opt -Uilyabb -S$SRVR_import -P$pw
done

for tbl in `cat GPS3_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag statistics -i${SRVR_export}/GPS3/${tbl}.opt -Uilyabb -S$SRVR_import -P$pw
done

for tbl in `cat GPS4_tbls`
do
/glsrd/database/sybase/ASE-12_5/bin/optdiag statistics -i${SRVR_export}/GPS4/${tbl}.opt -Uilyabb -S$SRVR_import -P$pw
done
