https://learn.microsoft.com/en-us/answers/questions/1095362/query-that-shows-run-start-and-duration-on-sql-age

select   
 j.name,
 j.enabled,
 run_date,  
 run_time,  
 msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',  
 run_duration  
From msdb.dbo.sysjobs j   
INNER JOIN msdb.dbo.sysjobhistory h   
 ON j.job_id = h.job_id   
where --j.enabled = 1  AND --Only Enabled Jobs
j.name = 'Update Datamart and Execute Rules Engine'
order by j.name, RunDateTime desc  