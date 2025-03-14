#!/bin/ksh
PATH=/usr/local/sybase/OCS-12_0/bin:/usr/openwin/bin:$PATH
LD_LIBRARY_PATH=/u/sybase/OCS-12_0/lib
SYBASE=/usr/local/sybase
export PATH
export LD_LIBRARY_PATH
export SYBASE

login=p489920
export login
SRVR=GLSR2D
export SRVR

PWFile="/u/p489920/IndexEval/EvalIndexUnused/pf"
chmod 400 $PWFile
pw=`cat $PWFile`
chmod 000 $PWFile

isql -U$login -S$SRVR -P$pw -otmp<< !

exec sp_configure 'number of worker processes',300
exec sp_configure 'max parallel degree',199
exec sp_configure 'max scan parallel degree',190
go

/**** unbind from cache  ****/

exec sp_unbindcache_all pt_trmast_idx_cache
go
!

isql -U$login -S$SRVR -P$pw -idrop_old_create_new_indexes.pt_trmast -opt_mrktomkt.newIndexes.pt_trmast.${SRVR}.out

isql -U$login -S$SRVR -P$pw -otmp1<< !

use master
go
exec sp_configure 'max scan parallel degree',1
exec sp_configure 'max parallel degree',1
exec sp_configure 'number of worker processes',0
go

/**** bind new indexes  ****/
use GPS
go
exec sp_bindcache pt_trmast_idx_cache, GPS, pt_trmast, pt_mrktomkt_CI
exec sp_bindcache pt_trmast_idx_cache, GPS, pt_trmast, pt_trmast_NCI1
exec sp_bindcache pt_trmast_idx_cache, GPS, pt_trmast, pt_trmast_NCI2
exec sp_bindcache pt_trmast_idx_cache, GPS, pt_trmast, pt_trmast_NCI3
exec sp_bindcache pt_trmast_idx_cache, GPS, pt_trmast, pt_trmast_NCI4
exec sp_bindcache pt_trmast_idx_cache, GPS, pt_trmast, pt_trmast_NCI5
exec sp_bindcache pt_trmast_idx_cache, GPS, pt_trmast, pt_trmast_NCI6
go
use GPS3
go
exec sp_bindcache pt_trmast_idx_cache, GPS3, pt_trmast, pt_mrktomkt_CI
exec sp_bindcache pt_trmast_idx_cache, GPS3, pt_trmast, pt_trmast_NCI1
exec sp_bindcache pt_trmast_idx_cache, GPS3, pt_trmast, pt_trmast_NCI2
exec sp_bindcache pt_trmast_idx_cache, GPS3, pt_trmast, pt_trmast_NCI3
exec sp_bindcache pt_trmast_idx_cache, GPS3, pt_trmast, pt_trmast_NCI4
exec sp_bindcache pt_trmast_idx_cache, GPS3, pt_trmast, pt_trmast_NCI5
exec sp_bindcache pt_trmast_idx_cache, GPS3, pt_trmast, pt_trmast_NCI6
go
use GPS4
go
exec sp_bindcache pt_trmast_idx_cache, GPS4, pt_trmast, pt_mrktomkt_CI
exec sp_bindcache pt_trmast_idx_cache, GPS4, pt_trmast, pt_trmast_NCI1
exec sp_bindcache pt_trmast_idx_cache, GPS4, pt_trmast, pt_trmast_NCI2
exec sp_bindcache pt_trmast_idx_cache, GPS4, pt_trmast, pt_trmast_NCI3
exec sp_bindcache pt_trmast_idx_cache, GPS4, pt_trmast, pt_trmast_NCI4
exec sp_bindcache pt_trmast_idx_cache, GPS4, pt_trmast, pt_trmast_NCI5
exec sp_bindcache pt_trmast_idx_cache, GPS4, pt_trmast, pt_trmast_NCI6
go
!
