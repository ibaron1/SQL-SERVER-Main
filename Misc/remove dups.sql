set rowcount 0

select ServerName, config
from syscurconfigs_15
group by ServerName, config
having count(*) > 1


declare @ServerName varchar(100), @config varchar(100)
set rowcount 1

while exists
(select * from syscurconfigs_15
group by ServerName, config
having count(*) > 1)
begin

select @ServerName = ServerName,@config = config  
from syscurconfigs_15
group by ServerName, config
having count(*) > 1

delete syscurconfigs_15
where ServerName = @ServerName and config = @config

end


