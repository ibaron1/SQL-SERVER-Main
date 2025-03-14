SELECT      OBJECT_SCHEMA_NAME(SO.object_id)                    AS SchemaName
          , OBJECT_NAME(SO.object_id)                           AS ObjectName
          , SO.type                                             AS ObjectType
          , SO.type_desc                                        AS ObjectTypeDescription
          , Utilities.SuperTrim(SSM.definition) AS ObjectDDL
FROM        sys.objects     AS SO
INNER JOIN  sys.sql_modules AS SSM ON
            SSM.object_id = SO.object_id
WHERE       REPLACE(Utilities.SuperTrim(SSM.definition),' ','') like '%LoanNumberasRecordId%'
ORDER BY    ObjectType ASC
          , SchemaName ASC
          , ObjectName ASC;
