select min(StartTime) as EQ_min_StartTime, MAX(EndTime) as EQ_max_EndTime 
from sys.fn_trace_gettable('\\nykpcm05701v05b\Archive\Rates\FALCON20140604075501_11\FALCON20140604075501_10.trc', default)

select TextData, hostname  
from sys.fn_trace_gettable('\\nykpcm05701v05b\Archive\Rates\FALCON20140604075501_11\FALCON20140604075501_10.trc', default)
where TextData like '%DbArchiveForEOD%'