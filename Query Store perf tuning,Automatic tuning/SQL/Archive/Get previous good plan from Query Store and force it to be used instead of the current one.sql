--https://learn.microsoft.com/en-us/sql/relational-databases/automatic-tuning/automatic-tuning?view=sql-server-ver16
/*
Whenever you notice a plan choice regression has occurred, you should find a previous good plan and force it to be used instead of the current one. 
This can be done by using the 
sp_query_store_force_plan procedure 
The Database Engine in SQL Server 2017 (14.x) provides information about regressed plans and recommended corrective actions. 
Additionally, Database Engine enables you to fully automate this process and let Database Engine fix any problem found related to the plan change.

The best practice would be to force the last known good plan because older plans might be invalid due to statistic or index changes. 
The user who forces the last known good plan should monitor performance of the query that is executed using the forced plan 
and verify that forced plan works as expected. 
Depending on the results of monitoring and analysis, the plan should be forced or the user should find another way to optimize the query, 
such as rewriting it. 
Manually forced plans should not be forced forever, because the Database Engine should be able to apply optimal plans. 
The user or DBA should eventually unforce the plan using 
sp_query_store_unforce_plan procedure
, and let the Database Engine find the optimal plan.

Tip
Alternatively, use the Queries With Forced Plans Query Store view to locate and unforce plans.

SQL Server provides all necessary views and procedures required to monitor performance and fix problems in Query Store.

Starting with SQL Server 2017 (14.x), the Database Engine detects and shows potential plan choice regressions 
and the recommended actions that should be applied in the 
https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-tuning-recommendations-transact-sql?view=sql-server-ver16
sys.dm_db_tuning_recommendations (Transact-SQL) DMV. 
The DMV shows information about the problem, the importance of the issue, and details such as the identified query, the ID of the regressed plan, 
the ID of the plan that was used as baseline for comparison, and the Transact-SQL statement that can be executed to fix the problem.
*/
