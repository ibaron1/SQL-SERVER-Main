select * from [dbo].[ChangeLog]
--where ObjectName = 'srf_main.SFreport' -- to check for a specific db object changes
order by EventDate desc
