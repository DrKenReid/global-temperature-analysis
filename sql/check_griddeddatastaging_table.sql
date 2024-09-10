USE [$(SQL_DATABASE_NAME)]

IF OBJECT_ID('dbo.GriddedDataStaging', 'U') IS NOT NULL
BEGIN
    -- Check row count
    SELECT COUNT(*) AS RowCount FROM GriddedDataStaging;

    -- Check first 10 rows
    SELECT TOP 10 * FROM GriddedDataStaging;

    -- Check for any NULL values
    SELECT 
        COUNT(*) AS TotalRows,
        SUM(CASE WHEN RawData IS NULL THEN 1 ELSE 0 END) AS NullRawData
    FROM GriddedDataStaging;
END
ELSE
BEGIN
    PRINT 'GriddedDataStaging table does not exist.';
END
