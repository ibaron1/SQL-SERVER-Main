How to Use Batch Size to Speed Mass Updates, Inserts and Deletes 

It is often necessary to perform mass updates, inserts, or deletes on a table or tables. If the action involves thousands to millions of rows, performance can bog down and the transaction log can grow very large, consuming much available disk space. In fact, updating millions of rows in one query may not even complete because the transaction log fills all available disk space and can no longer grow. Another problem occurs when log growth cannot not keep up with the space needed for the update. SQL will often error indicating the log is full when in fact there is plenty of disk space.

It is important to understand why this happens. SQL Server must keep all transactions in the transaction log until they are committed. This is necessary for rollback to occur in the event of an error. When thousands or millions of rows are updated in one transaction, all the information required for rollback is retained in the transaction log until the transaction commits or rolls back. Storing millions of rows in the log can cause it to grow large.

One way to overcome this problem and greatly improve performance of mass update queries is to perform the updates, inserts or deletes in smaller batches. Each batch should be enclosed in a transaction and the transaction committed after the specified number of rows have been processed. This is the same technique used by the DTS bulk insert task when the BatchSize property is set. (BTW, I highly recommend setting the BatchSize property when importing very large files into SQL Server tables.)

Here are samples of updates, deletes and inserts in batch transactions. In each example, the batch size is set at 50K. Another value may be optimal for different queries.

--Set UpdFlag in MyTable to 0 where KeyCol matches 
--primary key in ControlTable and UpdFlag not = 0.

--Set rowcount to 50000 to limit number of updates
--performed in each batch to 50K rows.
Set rowcount 50000

--Declare variable for row count
Declare @rc int
Set @rc=50000

While @rc=50000
 Begin

  Begin Transaction

  --Use tablockx and holdlock to obtain and hold 
  --an immediate exclusive table lock. This unusually
  --speeds the update because only one lock is needed.
  Update MyTable With (tablockx, holdlock)
    Set UpdFlag = 0
  From MyTable mt
  Join ControlTable ct
    On mt.KeyCol=ct.PK
  --Add criteria to avoid updating rows that
  --were updated in previous pass
  Where m.UpdFlag <> 0

  --Get number of rows updated
  --Process will continue until less than 50000
  Select @rc=@@rowcount

  --Commit the transaction
  Commit
 End

--Delete rows older than 90 days

--Set rowcount to 50000 to limit number of deletes per batch
Set rowcount 50000

--Declare variable for row count
Declare @rc int
Set @rc=50000

While @rc=50000
 Begin

  Begin Transaction

  --Use tablockx and holdlock to obtain and hold 
  --an immediate exclusive table lock. This unusually
  --speeds the update because only one lock is needed.
  Delete MyTable With (tablockx, holdlock)
  Where InsertDate < dateadd(d,-90,getdate())

  --Get number of rows updated
  --Process will continue until less than 50000
  Select @rc=@@rowcount

  --Commit the transaction
  Commit
 End

-----------------------------------------------------

--Insert rows into MyTable from ImportTable
--where key value doesn’t already exist.

--Set rowcount to 50000 to limit number of inserts per batch
Set rowcount 50000

--Declare variable for row count
Declare @rc int
Set @rc=50000

While @rc=50000
 Begin

  Begin Transaction

  --Use tablockx and holdlock to obtain and hold 
  --an immediate exclusive table lock. This usually
  --speeds the insert because only one lock is needed.
  Insert MyTable (KeyCol, Col1, Col2, Col3) With (tablockx, holdlock)
  Select i.ID, i.ColA, i.ColB, i.ColC
  From ImportTable i
  Left Join MyTable m
    On i.ID=m.KeyCol
  Where m.KeyCol Is Null

  --Get number of rows updated
  --Process will continue until less than 50000
  Select @rc=@@rowcount

  --Commit the transaction
  Commit
 End 

 
