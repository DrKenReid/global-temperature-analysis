USE [$(SQL_DATABASE_NAME)]

IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL
BEGIN
    -- Check row count
    SELECT COUNT(*) AS RowCount FROM TimeSeries;

    -- Check first 10 rows
    SELECT TOP 10 * FROM TimeSeries;

    -- Check for any NULL values
    SELECT 
        COUNT(*) AS TotalRows,
        SUM(CASE WHEN Year IS NULL THEN 1 ELSE 0 END) AS NullYears,
        SUM(CASE WHEN Temperature IS NULL THEN 1 ELSE 0 END) AS NullTemperatures
    FROM TimeSeries;
END
ELSE
BEGIN
    PRINT 'TimeSeries table does not exist.';
END
