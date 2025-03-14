select pending_disk_io_count from sys.dm_os_schedulers

/*
Using above TSQL if you get result greater than 0 (numbers >0) then it means the system is bound by IO, you need to get disks to perform better. 
BOL explains better on this value: 
Number of pending I/Os that are waiting to be completed. Each scheduler has a list of pending I/Os that are checked to determine 
whether they have been completed every time there is a context switch. The count is incremented when the request is inserted. 
This count is decremented when the request is completed. This number does not indicate the state of the I/Os. Is not nullable.
*/
