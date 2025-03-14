  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SELECT
    RADHE = 'CREATE PARTITION FUNCTION' + space(1) + quotename(spf.name) + 
'(' +  
    COALESCE(baset.name,'data type not found') +   ')' + CHAR(13) + 
    'AS RANGE ' + CASE WHEN CAST(spf.boundary_value_on_right AS int) = 1 
THEN 'RIGHT ' ELSE 'LEFT ' END  + CHAR(13) +
    'FOR VALUES (' +
    (SELECT STUFF(
    (SELECT
    [text()] = N',''' + CAST(
                      CASE st.system_type_id 
                       WHEN 40 THEN CONVERT (date, sprv.value,126) 
                       --WHEN 56 THEN CONVERT (int,  sprv.value)
                       --ELSE CONVERT (int,  sprv.value)
                      END 
                      AS NVARCHAR) + ''''
    FROM sys.partition_range_values sprv 
    WHERE sprv.function_id=spf.function_id
    order by sprv.boundary_id
     FOR XML PATH('') ), 1, 1,N'')+ N');')

    ,st.system_type_id
    ,spf.name AS [Name],
    spf.function_id AS [ID],
    CAST(spf.boundary_value_on_right AS int) AS [RangeType],
    spf.create_date AS [CreateDate],
    spf.fanout AS [NumberOfPartitions]
    FROM
    sys.partition_functions AS spf

    INNER JOIN sys.partition_parameters AS spp 
            ON spp.function_id=spf.function_id

    INNER JOIN sys.types AS st 
            ON st.system_type_id = st.user_type_id 
           and spp.system_type_id = st.system_type_id

    LEFT OUTER JOIN sys.types AS baset 
                  ON (     baset.user_type_id = spp.system_type_id 
                       and baset.user_type_id = baset.system_type_id) 

                  or (     (baset.system_type_id = spp.system_type_id) 
                       and (baset.user_type_id = spp.user_type_id) 
                       and (baset.is_user_defined = 0) 
                       and (baset.is_assembly_type = 1))
    --WHERE spf.name = 'PF_YEAR';