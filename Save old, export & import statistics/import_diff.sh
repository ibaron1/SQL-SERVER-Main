#!/bin/ksh
# param=db name
PATH=/usr/local/sybase/OCS-12_0/bin:/usr/openwin/bin:$PATH
LD_LIBRARY_PATH=/u/sybase/OCS-12_0/lib
SYBASE=/usr/local/sybase
export PATH
export LD_LIBRARY_PATH
export SYBASE

isql -Usa -Snyuxp02 -Psha1D0rsa1<< EOF
if exists (select * from tempdb..sysobjects where name="tbls_${1}_p2")
drop table tempdb..tbls_${1}_p2
go
select name=name,cnt=0 into tempdb..tbls_${1}_p2 from $1..sysobjects where type='U'
go
EOF

bcp tempdb..tbls_${1}_p2 out tbls_${1}_p2 -Usa -Snyuxp02 -Psha1D0rsa1 -c

for tbl in `cut -f1 tbls_${1}_p2`
do
isql -Usa -Snyuxp02 -Psha1D0rsa1<< EOF
update tempdb..tbls_${1}_p2
set cnt=(select count(*) from $1..${tbl})
where name="${tbl}"
go
EOF
done

isql -Usa -Snyuxp01 -Psha1D0rsa1<< EOF
if exists (select * from tempdb..sysobjects where name="tbls_${1}_p1")
drop table tempdb..tbls_${1}_p1
go
select name=name,cnt=0 into tempdb..tbls_${1}_p1 from $1..sysobjects where type='U'
go
EOF

bcp tempdb..tbls_${1}_p1 out tbls_${1}_p1 -Usa -Snyuxp01 -Psha1D0rsa1 -c

for tbl in `cut -f1 tbls_${1}_p1`
do
isql -Usa -Snyuxp01 -Psha1D0rsa1<< EOF
update tempdb..tbls_${1}_p1
set cnt=(select count(*) from $1..${tbl})
where name="${tbl}"
go
EOF
done

bcp tempdb..tbls_${1}_p1 out  tbls_${1}_p1 -Usa -Snyuxp01 -Psha1D0rsa1 -c

isql -Usa -Snyuxp02 -Psha1D0rsa1<< EOF
if exists (select * from tempdb..sysobjects where name="tbls_${1}_p1")
drop table tempdb..tbls_${1}_p1
go
select * into tempdb..tbls_${1}_p1 from tempdb..tbls_${1}_p2 where 1=2
go
EOF

bcp tempdb..tbls_${1}_p1 in tbls_${1}_p1 -Usa -Snyuxp02 -Psha1D0rsa1 -c

isql -Usa -Snyuxp02 -Psha1D0rsa1<< EOF
if exists (select * from tempdb..sysobjects where name="tbls_not_in_${1}")
drop table tempdb..tbls_not_in_${1}
go
if exists (select * from tempdb..sysobjects where name="tbls_diff_${1}")
drop table tempdb..tbls_diff_${1}
go
select name into tempdb..tbls_not_in_${1} from tempdb..tbls_${1}_p1 
where name not in (select name from tempdb..tbls_${1}_p2)

select p1.name name, p1.cnt cnt_p1, p2.cnt cnt_p2
into tempdb..tbls_diff_${1}
from tempdb..tbls_${1}_p1 p1, tempdb..tbls_${1}_p2 p2
where p1.name=p2.name and p1.cnt <> p2.cnt
go
EOF

bcp tempdb..tbls_not_in_${1} out tbls_not_in_${1} -Usa -Snyuxp02 -Psha1D0rsa1 -c
bcp tempdb..tbls_diff_${1} out tbls_diff_${1} -Usa -Snyuxp02 -Psha1D0rsa1 -c
