/*
https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-schedulers-transact-sql
column name
Description
Data type
scheduler address
parent _ node id int
scheduler id
int
cpu_id small int
Is not nullable.
varbinary (8) memory address of the scheduler. IS not nullable.
ID of the node that the scheduler belongs to, also known as the parent node. This represents a nonuniform memory access (NIJMA) node. Is not nullable.
ID of the scheduler. All schedulers that are used to run regular queries have ID numbers less than 1048576. Those schedulers that have IDs greater than or equal to 1048576 are used internally by SQL Server,
CPU ID assigned to the scheduler.
such as the dedicated administrator connection scheduler.
Is not nullable.
Note: 255 does not indicate no affinity as it did in SQL Server 2005. See sys.dm_os_threads (Transact-SQL) for additional affinity information.
status nvarchar(60)
Indicates the status of the scheduler. Can be one of the following values;
- HIDDEN ONLINE
- HIDDEN OFFLINE
- VISIBLE ONLINE
- VISIBLE OFFLINE
- VISIBLE ONLINE (DAC)
- HOT ADDED
IS not nullable.
HIDDEN schedulers are used to process requests that are internal to the Database Engine. VISIBLE schedulers are used to process user requests.
OFFLINE schedulers map to processors that are offline in the affinity mask and are, therefore, not being used to process any requests. ONLINE schedulers map to processors that are online in the affinity mask and are available to process threads.
DAC indicates the scheduler is running under a dedicated administrator connection.
HOT ADDED indicates the schedulers were added in response to a hot add CPU event.
is online bit If SQL Server is configured to use only some of the available processors on the server, this configuration can mean that some schedulers are mapped to processors that are not in the affinity mask.
If that is the case, this column returns 0.
This value means that the scheduler is not being used to process queries or batches.
IS not nullable.
is_idle bit 1 = scheduler is idle. NO workers are currently running. IS not nullable.
preemptive switches _ count int Number of times that workers on this scheduler have switched to the preemptive mode.
TO execute code that is outside SQL server (for example, extended stored procedures and distributed queries), a thread has to execute outside the control of the non-preemptive scheduler.
context switches count int Number of context switches that have occurred on this scheduler. IS not nullable.
TO allow for other workers to run, the current running worker has to relinquish control of the scheduler or switch context.

Note: If a worker yields the scheduler and puts itself into the runnable queue and then finds no other workers, the worker will select itself. rn this case, the context switches_count is not updated, but the yield _ count is updated.
a worker switches to preemptive mode.

idle_switches_count int 
current_tasks_count int 


Number of times the scheduler has been waiting for an event while idle. This column is similar to context _ switches _ count. Is not nullable.
Number of current tasks that are associated with this scheduler. This count includes the following:
- Tasks that are waiting for a worker to execute them.
- Tasks that are currently waiting or running (in SUSPENDED or RUNNABLE state)
When a task is completed, this count is decremented. Is not nullable.
runnable_tasks_count int Number of workers, with tasks assigned to them, that are waiting to be scheduled on the runnable queue. Is not nullable.
current_workers_count int Number of workers that are associated with this scheduler. This count includes workers that are not assigned any task. Is not nullable.
active_workers_count int Number of workers that are active. An active worker is never preemptive, must have an associated task, and is either running, runnable, or suspended. Is not nullable.
work_queue_count bigint Number of tasks in the pending queue. These tasks are waiting for a worker to pick them up. Is not nullable.
pending_disk_io_count int pending I/os that are waiting to be completed. Each scheduler has a list of pending 1/0s that are checked to determine whether they have been completed every time there is a context switch.

does not indicate the
load factor
int
scheduler. SQL Server
ield_countl
int
last _ timer _ activity
state of the 1/0s. Is not nullable.
Internal value that indicates the perceived load on this scheduler. This value is used to determine whether a new task should be put on this scheduler or another scheduler. This value is useful for debugging purposes when it appears that schedulers are not evenly loaded. The routing decision is made based on the load on the
also uses a load factor of nodes and schedulers to help determine the best location to acquire resources. When a task is enqueued, the load factor is increased. When a task is completed, the load factor is decreased. Using the load factors helps SQL Server OS balance the work load better. Is not nullable.
Internal value that is used to indicate progress on this scheduler. This value is used by the Scheduler monitor to determine whether a worker on the scheduler is not yielding to other workers on time. This value does not indicate that the worker or task transitioned to a new worker. Is not nullable.
bigint In CPU ticks, the last time that the scheduler timer queue was checked by the scheduler. Is not nullable.
ailed to create worker bit
Set to 1 if a new worker could not be created on this scheduler. This generally occurs because of memory constraints. Is nullable.
active worker address
varbinary(8)
Memory address of the worker that is currently active. Is nullable. For more information, see sys.dm_os_workers (Transact-SQL).
memory _ object _ address
varbinary(8)
Memory address of the scheduler memory object. Not NULLABLE.
ask_memory_object_address
varbinary(8)
Memory address of the task memory object. Is not nullable. For more information, see sys.dm_os_memory_objects (Transact-SQL).
quantum_length_us
pdw_node id
int
bigint Identified for informational purposes only. Not supported. Future compatibility is not guaranteed. Exposes the scheduler quantum used by SQLOS.
Applies to: Azure SQL Data Warehouse, Parallel Data Warehouse
The identifier for the node that this distribution is on.
*/

select load_factor,* from sys.dm_os_schedulers 

SELECT
scheduler_id,
cpu_id,
parent_node_id,
current_tasks_count,
runnable_tasks_count,
current_workers_count,
active_workers_count,
work_queue_count
FROM sys.dm_os_schedulers;