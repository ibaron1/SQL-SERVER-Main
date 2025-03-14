/****************************************************************************/
/*                Expert SQL Server Transactions and Locking                */
/*            APress. ISBN-13: 978-1484239568 ISBN-10: 1484239563           */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                      Chapter 09. Lock Partitioning				        */
/*                  Lock Partitioning Deadlock (Session 2)                  */
/****************************************************************************/

-- You need to have 16 or more schedulers for lock partitioning to be enabled

-- You can artificially change number of cores with undocumented startup flag -P[N] 
-- [N] is number of cores. DO NOT DO THIS IN PRODUCTION!


use SQLServerInternals
go

-- No issues here
alter index PK_Orders on Delivery.Orders rebuild
go
