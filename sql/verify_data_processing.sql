-- detailed_verify_data_processing.sql
USE GlobalTemperatureAnalysis;
GO

SET NOCOUNT ON;

-- Check TimeSeries table
PRINT 'TimeSeries table statistics:';
IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL
BEGIN
    SELECT COUNT(*) AS TotalRows, ISNULL(MIN(Year), 'N/A') AS MinYear, ISNULL(MAX(Year), 'N/A') AS MaxYear, 
           ISNULL(CAST(AVG(Temperature) AS DECIMAL(10,2)), 'N/A') AS AvgTemperature
    FROM TimeSeries;
END
ELSE
BEGIN
    PRINT 'TimeSeries table does not exist.';
END

-- Check GriddedDataStaging table
PRINT 'GriddedDataStaging table status:';
IF OBJECT_ID('dbo.GriddedDataStaging', 'U') IS NOT NULL
BEGIN
    PRINT 'Warning: GriddedDataStaging table still exists. It should have been dropped after processing.';
    SELECT COUNT(*) AS RemainingRows FROM GriddedDataStaging;
END
ELSE
BEGIN
    PRINT 'GriddedDataStaging table has been dropped as expected.';
END

-- Check GriddedData table
PRINT 'GriddedData table statistics:';
IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    SELECT COUNT(*) AS TotalRows, 
           COUNT(DISTINCT RowID) AS UniqueRows, 
           COUNT(DISTINCT ColumnID) AS UniqueColumns,
           ISNULL(CAST(AVG(Value) AS DECIMAL(10,2)), 'N/A') AS AverageValue, 
           ISNULL(MIN(Value), 'N/A') AS MinValue, 
           ISNULL(MAX(Value), 'N/A') AS MaxValue
    FROM GriddedData;

    -- Sample data from GriddedData
    PRINT 'Sample data from GriddedData:';
    SELECT TOP 5 * FROM GriddedData;
END
ELSE
BEGIN
    PRINT 'GriddedData table does not exist.';
END

-- Check for any error messages in the SQL Server log
PRINT 'Recent error messages from SQL Server log:';
SELECT TOP 10 
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_MESSAGE() AS ErrorMessage
FROM sys.dm_exec_requests 
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
WHERE session_id <> @@SPID
ORDER BY start_time DESC;
