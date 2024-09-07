USE [$(SQL_DATABASE_NAME)]

-- Check row count
SELECT COUNT(*) AS RowCount FROM GriddedDataStaging;

-- Check first 10 rows
SELECT TOP 10 * FROM GriddedDataStaging;

-- Check for any NULL values
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN RawData IS NULL THEN 1 ELSE 0 END) AS NullRawData
FROM GriddedDataStaging;
