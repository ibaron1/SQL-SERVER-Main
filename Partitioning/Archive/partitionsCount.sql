CREATE OR ALTER FUNCTION Processing.partitionsCount (@table VARCHAR(200))
RETURNS INT
AS
BEGIN
	RETURN
		(SELECT count (DISTINCT P.partition_number)
		FROM sys. partitions AS P
		WHERE P.object_id = OBJECT_ID(@table));

END;