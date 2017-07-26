-- all workflows
select ActivityKeyWorkflow,
max(cast(time_after_model3Proc_run as char(19))) as [Executed time from tranDetailsModel3_metrics]
,avg(datediff(ms,time_before_model3Proc_run,time_after_model3Proc_run)) as [Avg run time in ms over 1 sec] 
,count(1) as [Proc's executions # over 1 sec]
from tranDetailsModel3_metrics
group BY ActivityKeyWorkflow,DATEADD(second, -DATEDIFF(second, CAST(convert(char(19), time_after_model3Proc_run, 108) AS DATE), convert(char(19), time_after_model3Proc_run, 108)) % 1, convert(char(19), time_after_model3Proc_run, 108))
order by ActivityKeyWorkflow,[Executed time from tranDetailsModel3_metrics]

-- workflows
select ActivityKeyWorkflow,
max(cast(time_after_model3Proc_run as char(19))) as [Executed time from tranDetailsModel3_metrics]
,avg(datediff(ms,time_before_model3Proc_run,time_after_model3Proc_run)) as [Avg run time in ms over 1 sec] 
,count(1) as [Proc's executions # over 1 sec]
from tranDetailsModel3_metrics
where ActivityKeyWorkflow = 'ActivityKeyWorkflow1'
group BY ActivityKeyWorkflow,DATEADD(second, -DATEDIFF(second, CAST(convert(char(19), time_after_model3Proc_run, 108) AS DATE), convert(char(19), time_after_model3Proc_run, 108)) % 1, convert(char(19), time_after_model3Proc_run, 108))
order by ActivityKeyWorkflow,[Executed time from tranDetailsModel3_metrics]

select ActivityKeyWorkflow,
max(cast(time_after_model3Proc_run as char(19))) as [Executed time from tranDetailsModel3_metrics]
,avg(datediff(ms,time_before_model3Proc_run,time_after_model3Proc_run)) as [Avg run time in ms over 1 sec] 
,count(1) as [Proc's executions # over 1 sec]
from tranDetailsModel3_metrics
where ActivityKeyWorkflow = 'ActivityKeyWorkflow2'
group BY ActivityKeyWorkflow,DATEADD(second, -DATEDIFF(second, CAST(convert(char(19), time_after_model3Proc_run, 108) AS DATE), convert(char(19), time_after_model3Proc_run, 108)) % 1, convert(char(19), time_after_model3Proc_run, 108))
order by ActivityKeyWorkflow,[Executed time from tranDetailsModel3_metrics]

select ActivityKeyWorkflow,
max(cast(time_after_model3Proc_run as char(19))) as [Executed time from tranDetailsModel3_metrics]
,avg(datediff(ms,time_before_model3Proc_run,time_after_model3Proc_run)) as [Avg run time in ms over 1 sec] 
,count(1) as [Proc's executions # over 1 sec]
from tranDetailsModel3_metrics
where ActivityKeyWorkflow = 'ActivityKeyWorkflow3'
group BY ActivityKeyWorkflow,DATEADD(second, -DATEDIFF(second, CAST(convert(char(19), time_after_model3Proc_run, 108) AS DATE), convert(char(19), time_after_model3Proc_run, 108)) % 1, convert(char(19), time_after_model3Proc_run, 108))
order by ActivityKeyWorkflow,[Executed time from tranDetailsModel3_metrics]

select ActivityKeyWorkflow,
max(cast(time_after_model3Proc_run as char(19))) as [Executed time from tranDetailsModel3_metrics]
,avg(datediff(ms,time_before_model3Proc_run,time_after_model3Proc_run)) as [Avg run time in ms over 1 sec] 
,count(1) as [Proc's executions # over 1 sec]
from tranDetailsModel3_metrics
where ActivityKeyWorkflow = 'ActivityKeyWorkflow4'
group BY ActivityKeyWorkflow,DATEADD(second, -DATEDIFF(second, CAST(convert(char(19), time_after_model3Proc_run, 108) AS DATE), convert(char(19), time_after_model3Proc_run, 108)) % 1, convert(char(19), time_after_model3Proc_run, 108))
order by ActivityKeyWorkflow,[Executed time from tranDetailsModel3_metrics]

select ActivityKeyWorkflow,
max(cast(time_after_model3Proc_run as char(19))) as [Executed time from tranDetailsModel3_metrics]
,avg(datediff(ms,time_before_model3Proc_run,time_after_model3Proc_run)) as [Avg run time in ms over 1 sec] 
,count(1) as [Proc's executions # over 1 sec]
from tranDetailsModel3_metrics
where ActivityKeyWorkflow = 'ActivityKeyWorkflow5'
group BY ActivityKeyWorkflow,DATEADD(second, -DATEDIFF(second, CAST(convert(char(19), time_after_model3Proc_run, 108) AS DATE), convert(char(19), time_after_model3Proc_run, 108)) % 1, convert(char(19), time_after_model3Proc_run, 108))
order by ActivityKeyWorkflow,[Executed time from tranDetailsModel3_metrics]