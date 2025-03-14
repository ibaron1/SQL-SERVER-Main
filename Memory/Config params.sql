sp_configure 'allocate max shared memory',0 -- 0 - dynamic allocation (default), 1 -- allocate max shared memory 

/****
allocate max shared memory determines whether Adaptive Server allocates 
all the memory specified by max memory at start-up 
or only the amount of memory the configuration parameter requires.
****/