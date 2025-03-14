/****************************************************************************/
/*                         SQL Server Internals v3                          */
/*                           Training Materials                             */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                         Diagnostics Scripts                              */
/*                           Wait Statistics                                */
/****************************************************************************/

;WITH Waits
AS
(
  SELECT 
    wait_type, wait_time_ms, waiting_tasks_count,signal_wait_time_ms
    ,wait_time_ms - signal_wait_time_ms AS resource_wait_time_ms
    ,100. * wait_time_ms / SUM(wait_time_ms) OVER() AS Pct
    ,100. * SUM(wait_time_ms) OVER(ORDER BY wait_time_ms DESC) /
        NULLIF(SUM(wait_time_ms) OVER(), 0) AS RunningPct
	,ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
  FROM sys.dm_os_wait_stats WITH (NOLOCK)
  WHERE 
    wait_type NOT IN /* Filtering out non-essential system waits */
    (N'BROKER_EVENTHANDLER',N'BROKER_RECEIVE_WAITFOR',N'BROKER_TASK_STOP'
    ,N'BROKER_TO_FLUSH',N'BROKER_TRANSMITTER',N'CHECKPOINT_QUEUE',N'CHKPT'
    ,N'CLR_SEMAPHORE',N'CLR_AUTO_EVENT',N'CLR_MANUAL_EVENT'
    ,N'DBMIRROR_DBM_EVENT',N'DBMIRROR_EVENTS_QUEUE',N'DBMIRROR_WORKER_QUEUE'
    ,N'DBMIRRORING_CMD',N'DIRTY_PAGE_POLL',N'DISPATCHER_QUEUE_SEMAPHORE'
    ,N'EXECSYNC',N'FSAGENT',N'FT_IFTS_SCHEDULER_IDLE_WAIT',N'FT_IFTSHC_MUTEX'
	,N'HADR_CLUSAPI_CALL',N'HADR_FILESTREAM_IOMGR_IOCOMPLETION'
    ,N'HADR_LOGCAPTURE_WAIT',N'HADR_NOTIFICATION_DEQUEUE'
    ,N'HADR_TIMER_TASK',N'HADR_WORK_QUEUE',N'KSOURCE_WAKEUP',N'LAZYWRITER_SLEEP'
    ,N'LOGMGR_QUEUE',N'ONDEMAND_TASK_QUEUE'
    ,N'PARALLEL_REDO_WORKER_WAIT_WORK',N'PARALLEL_REDO_DRAIN_WORKER'
    ,N'PARALLEL_REDO_LOG_CACHE',N'PARALLEL_REDO_TRAN_LIST'
    ,N'PARALLEL_REDO_WORKER_SYNC',N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS'
    ,N'PREEMPTIVE_OS_LIBRARYOPS',N'PREEMPTIVE_OS_COMOPS', N'PREEMPTIVE_OS_PIPEOPS'
    ,N'PREEMPTIVE_OS_GENERICOPS',N'PREEMPTIVE_OS_VERIFYTRUST'
    ,N'PREEMPTIVE_OS_FILEOPS',N'PREEMPTIVE_OS_DEVICEOPS'
    ,N'PREEMPTIVE_OS_QUERYREGISTRY',N'PREEMPTIVE_XE_CALLBACKEXECUTE'
    ,N'PREEMPTIVE_XE_DISPATCHER',N'PREEMPTIVE_XE_GETTARGETSTATE'
    ,N'PREEMPTIVE_XE_SESSIONCOMMIT',N'PREEMPTIVE_XE_TARGETINIT'
    ,N'PREEMPTIVE_XE_TARGETFINALIZE',N'PWAIT_ALL_COMPONENTS_INITIALIZED'
    ,N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',N'PWAIT_EXTENSIBILITY_CLEANUP_TASK'
    ,N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',N'QDS_ASYNC_QUEUE'
    ,N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'
    ,N'REQUEST_FOR_DEADLOCK_SEARCH',N'RESOURCE_QUEUE',N'SERVER_IDLE_CHECK'
    ,N'SLEEP_BPOOL_FLUSH',N'SLEEP_DBSTARTUP',N'SLEEP_DCOMSTARTUP'
    ,N'SLEEP_MASTERDBREADY',N'SLEEP_MASTERMDREADY',N'SLEEP_MASTERUPGRADED'
    ,N'SLEEP_MSDBSTARTUP',N'SLEEP_SYSTEMTASK',N'SLEEP_TASK'
    ,N'SLEEP_TEMPDBSTARTUP',N'SNI_HTTP_ACCEPT',N'SOS_WORK_DISPATCHER'
    ,N'SP_SERVER_DIAGNOSTICS_SLEEP',N'SQLTRACE_BUFFER_FLUSH'
    ,N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',N'SQLTRACE_WAIT_ENTRIES'
    ,N'STARTUP_DEPENDENCY_MANAGER',N'WAIT_FOR_RESULTS'
    ,N'WAITFOR',N'WAITFOR_TASKSHUTDOWN',N'WAIT_XTP_HOST_WAIT'
    ,N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',N'WAIT_XTP_CKPT_CLOSE',N'WAIT_XTP_RECOVERY'
    ,N'XE_BUFFERMGR_ALLPROCESSED_EVENT',N'XE_DISPATCHER_JOIN',N'XE_DISPATCHER_WAIT'
    ,N'XE_LIVE_TARGET_TVF',N'XE_TIMER_EVENT')
)
SELECT
  w1.wait_type AS [Wait Type]
  ,w1.waiting_tasks_count AS [Wait Count]
  ,CONVERT(DECIMAL(12,3), w1.wait_time_ms / 1000.0) AS [Wait Time]
  ,CONVERT(DECIMAL(12,1), w1.wait_time_ms / w1.waiting_tasks_count) 
        AS [Avg Wait Time]
  ,CONVERT(DECIMAL(12,3), w1.signal_wait_time_ms / 1000.0) 
        AS [Signal Wait Time]
  ,CONVERT(DECIMAL(12,1), w1.signal_wait_time_ms / w1.waiting_tasks_count) 
        AS [Avg Signal Wait Time]
  ,CONVERT(DECIMAL(12,3), w1.resource_wait_time_ms / 1000.0) 
        AS [Resource Wait Time]
  ,CONVERT(DECIMAL(12,1), w1.resource_wait_time_ms / w1.waiting_tasks_count) 
        AS [Avg Resource Wait Time]
  ,CONVERT(DECIMAL(6,3), w1.Pct) 
        AS [Percent]
  ,CONVERT(DECIMAL(6,3), w1.RunningPct) 
        AS [Running Percent]
FROM
	Waits w1
WHERE
	w1.RunningPct <= 99 OR w1.RowNum = 1
ORDER BY
	w1. RunningPct  
OPTION (RECOMPILE, MAXDOP 1);
