--verify average run time over 1 sec interval
;with a_time
as
(select ActivityKeyWorkflow, datediff(ms,time_before_model3Proc_run,time_after_model3Proc_run) as run_time_ms
from tranDetailsModel3_metrics
where ActivityKeyWorkflow = 'ActivityKeyWorkflow5'
and time_after_model3Proc_run >= '2017-07-25 14:28:48' 
and time_after_model3Proc_run < '2017-07-25 14:28:49')
select count(1) as [Proc's executions # over 1 sec], avg(run_time_ms) as [Avg run time in ms over 1 sec]
from a_time
group by ActivityKeyWorkflow