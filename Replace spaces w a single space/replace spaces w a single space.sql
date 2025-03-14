declare @a table(a varchar(400))

insert @a
select 'a   b c    '

--remove all spaces

select a, 
replace(a,' ','<>'),
 replace(replace(a,' ','<>'),'><',''),                                                  
       replace(replace(replace(a,' ','<>'),'><',''),'<>','')
from @a


-- leave just 1 space 
select a,                                                    
       replace(replace(replace(a,' ','<>'),'><',''),'<>',' ')
from @a


