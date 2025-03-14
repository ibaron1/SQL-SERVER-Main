However, permissions can be complicated. For example, setting DENY permissions on a securable prevents permission inheritance on lower-level objects. But the column-level GRANT permission overrides DENY at the object level, so DENY permission set on a table is overridden by GRANT permission on a column. Because permissions can be complex, it’s always worth checking effective permissions using T-SQL. The following command determines JoeB’s permissions granted on an object, in this case a table called ‘employees’.

SELECT * FROM fn_my_permissions(‘joeb’, employees);
GO

