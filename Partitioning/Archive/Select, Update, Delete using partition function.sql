SET STATISTICS PROFILE, TIME, IO ON
GO

DECLARE @EffectiveDate DATE = DateReference.EffectiveDate(); -- 2024-11-22

SELECT @EffectiveDate AS [@EffectiveDate];

-- SELECT $PARTITION.pf_DateByMonthRight(@EffectiveDate);

/* Reset RecordStartDate/RecordEndDate (for reruns) */
UPDATE L
SET RecordEndDate = NULL
FROM DataMart_History.Loan AS L WITH (INDEX=IX_RecordEndDate, FORCESEEK)
WHERE L.RecordEndDate = @EffectiveDate
AND $PARTITION.pf_DateByMonthRight(L.RecordEndDate) = $PARTITION.pf_DateByMonthRight(@EffectiveDate);

SELECT $PARTITION.pf_DateByMonthRight(RecordEndDate) -- , COUNT(1) AS _count
FROM DataMart_History.Loan
WHERE RecordEndDate = @EffectiveDate
AND $PARTITION.pf_DateByMonthRight(RecordEndDate) = $PARTITION.pf_DateByMonthRight(@EffectiveDate)
-- GROUP BY $PARTITION.pf_DateByMonthRight(RecordEndDate)

