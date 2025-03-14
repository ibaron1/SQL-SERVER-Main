The STUFF function 

You use the STUFF function to remove a substring from a string and insert a new substring instead. 

Syntax STUFF(string, pos, delete_length, insert_string) 

SELECT STUFF('xyz', 2, 1, 'abc'); 

The output of this code is 'xabcz'. 

If you just want to insert a string without deleting anything, you can specify a length of 0 as the third argument. If you only want to delete a substring but not insert anything instead, specify a NULL as the fourth argument. 
