/*
create table CUSTOM..GLSR2_mempool_err(msg varchar(1000))

bcp CUSTOM..GLSR2_mempool_err in /tmp/err.mempool -Uilyabb -SGLSR2D -c

create table GLSR2_mempool_dtls
(cache_name varchar(18),
pool_size varchar(3),
cachelet_id char(1),
date_logged datetime,
day_logged char(10),
time_logged char(11),
msg varchar(1000)
*/


insert GLSR2_mempool_dtls
select
substring(msg, charindex('cache',msg)+6, charindex('(cache',msg)-(charindex('cache',msg)+6)-1), --cache name
substring(msg, charindex('server',msg)+12, 3), --pool size
substring(msg, charindex('cachelet',msg)+12, 1), --cachelet id
substring(msg, charindex('server',msg)-23, 22), --datetime
substring(msg, charindex('server',msg)-23, 10), --date
substring(msg, charindex('server',msg)-12, 11), --time
msg 
from GLSR2_mempool_err

--------------------------------------------------------------------

select distinct cache_name, pool_size, cachelet_id, count(*) 
from CUSTOM..GLSR2_mempool_dtls
group by cache_name, pool_size, cachelet_id
order by cache_name, pool_size desc, cachelet_id

