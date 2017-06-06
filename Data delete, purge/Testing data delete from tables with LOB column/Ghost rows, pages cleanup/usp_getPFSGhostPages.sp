--This procedure prints all pages and corresponding PFS page information for a given input database and table.

--Usage : exec usp_getPFSGhostPages @dbname, @tablename

--Example:

--exec usp_getPFSGhostPages 'pubs', 'authors'

SET NOCOUNT ON

GO

CREATE PROCEDURE dbo.usp_getPFSGhostPages @dbname varchar(100), @tablename varchar(100)

AS
--exec usp_getPFSGhostPages 'FALCON_SRF_Rates', 'srf_main.EODBusinessException'
BEGIN

      SET NOCOUNT ON

      SET ANSI_WARNINGS OFF

     --Declare variables

      declare @file_id varchar(10), @page_id varchar(50), @dbccpagecmd varchar(100), @dbccextentcmd varchar(100)



      --Create Temp Tables

      create table #extentinfo (file_id int, page_id int, pg_alloc  int,ext_size int, object_id varchar(15),

      index_id int, partition_number int, partition_id varchar(25),iam_chain_type varchar(15),pfs_bytes varbinary)

      create table #PageInfo (ParentObject varchar(25), Object varchar(50), Field varchar(50), Value varchar(50))

      create table #PFSPage (ObjectID varchar(20), PageID varchar(20), SlotCount int, GhostRecordCount int, PFSPageID varchar(50))



      --Populate extentinfo for input database and table

set @dbccextentcmd = 'DBCC EXTENTINFO('+ @dbname + ','+ Quotename (@tablename,'''') + ',-1) with no_infomsgs'

      insert into #extentinfo exec (@dbccextentcmd)



      --Run DBCC PAGE for each page in #extentinfo. Retrieve necessary fields  into #PFSPage.

      --At the end of the cursor execution, #PFSPage should have (objectid, pageid, slotcount, ghostrecordcount, pfspageid) for every page of the input table.

      declare pageloop cursor for

      select file_id, page_id from #extentinfo

      open pageloop

      fetch next from pageloop into @file_id, @page_id

      WHILE @@FETCH_STATUS = 0

      BEGIN

            --select @file_id, @page_id

            set @dbccpagecmd = 'DBCC PAGE('+ @dbname + ','+ @file_id + ','+@page_id+',0) with no_infomsgs, tableresults'

            --select @dbccpagecmd

            insert #PageInfo exec (@dbccpagecmd)

            insert #PFSPage 

            select max(case when Field = 'Metadata: ObjectId' then Value end) as ObjectID, 

                   max(case when Field = 'm_PageId' then Value end) as PageID, 

                   max(case when Field = 'm_slotCnt' then Value end) as SlotCount, 

                   max(case when Field = 'm_ghostRecCnt' then Value end) as GhostRecordCount, 

                   max(case when Field like 'PFS%' then substring(Field, (CHARINDEX('(', Field)+1), LEN(Field)-(CHARINDEX('(', Field)+1)) end) as PFSPageID

            from #PageInfo

            where Field in ('Metadata: ObjectId','m_pageId','m_slotCnt', 'm_ghostRecCnt') or Field like 'PFS%'

            TRUNCATE table #PageInfo

            fetch next from pageloop into @file_id, @page_id

      END

      CLOSE pageloop

      DEALLOCATE pageloop



      --Print all input table's pages with ghost records and their PFS pages

      PRINT 'DATA PAGE and PFS Page information for ' + @tablename

      SELECT PageID, SlotCount, GhostRecordCount, PFSPageID FROM #PFSPage 

      WHERE GhostRecordCount > 0

      



      --Turn on TF 3604 for DBCC PAGE output. 

      DBCC TRACEON(3604)

     

      declare pageloop cursor for

      select DISTINCT PFSPageID from #PFSPage where GhostRecordCount > 0

      open pageloop

      fetch next from pageloop into @page_id

      WHILE @@FETCH_STATUS = 0

      BEGIN

      

            PRINT 'Executing DBCC PAGE on PFS Page ' + @page_id

            set @dbccpagecmd = 'DBCC PAGE('+ @dbname + ','+ REPLACE(@page_id, ':', ',')+',3) with no_infomsgs'

            --select @dbccpagecmd

            exec(@dbccpagecmd)

            fetch next from pageloop into @page_id

      END

      CLOSE pageloop

      DEALLOCATE pageloop

      

      DBCC TRACEOFF(3604)

      

      --Drop Temp Tables

      drop table #extentinfo

      drop table #PageInfo

      drop table #PFSPage



END

