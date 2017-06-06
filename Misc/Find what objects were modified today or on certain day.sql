
-- Find objects modified today
select '' as [Objects modified today], name, type, modify_date, create_date from sys.objects where type <> 'S' and cast(modify_date as date) = cast(getdate() as date) and modify_date <> create_date order by modify_date

-- Find objects created today
select '' as [Objects created today], name, type, modify_date, create_date from sys.objects where type <> 'S' and cast(modify_date as date) = cast(getdate() as date) and modify_date = create_date order by modify_date

-- Find objects modified at some time day
select name, type, modify_date, create_date from sys.objects 
where type <> 'S' and cast(modify_date as date) = '2012-01-11' and modify_date <> create_date order by modify_date

-- Find objects not modified at some day
select name, type, modify_date, create_date from sys.objects 
where type <> 'S' and cast(modify_date as date) = '2012-01-11' and modify_date = create_date order by modify_date

-- Find objects modified during some period of time
select name, type, modify_date, create_date from sys.objects 
where type <> 'S' and cast(modify_date as date) between '2012-01-11' and '2012-06-26' 
and modify_date <> create_date 
order by modify_date

-- Find objects not modified during some period of time
select name, type, modify_date, create_date from sys.objects 
where type <> 'S' and modify_date between '2012-01-11' and '2012-06-26' 
and modify_date = create_date
order by modify_date











