TRUNCATE TABLE test_history.[CorporateAdvanceTransactions]
WITH (PARTITIONS ($PARTITION.pf_DateByYearMonthInt(202409)));