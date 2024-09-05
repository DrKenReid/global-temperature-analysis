-- detailed_verify_data_processing.sql
USE GlobalTemperatureAnalysis

SET NOCOUNT ON

-- Check if TimeSeries table exists
SELECT CASE 
    WHEN OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL THEN 'TimeSeries table exists'
    ELSE 'TimeSeries table does not exist'
END AS TimeSeries_Status

-- Get TimeSeries statistics if it exists
IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL
BEGIN
    SELECT COUNT(*) AS TotalRows, 
           MIN(Year) AS MinYear, 
           MAX(Year) AS MaxYear,
           AVG(Temperature) AS AvgTemperature
    FROM TimeSeries
END

-- Check if GriddedDataStaging table exists
SELECT CASE 
    WHEN OBJECT_ID('dbo.GriddedDataStaging', 'U') IS NOT NULL THEN 'GriddedDataStaging table exists'
    ELSE 'GriddedDataStaging table does not exist'
END AS GriddedDataStaging_Status

-- Get GriddedDataStaging count if it exists
IF OBJECT_ID('dbo.GriddedDataStaging', 'U') IS NOT NULL
BEGIN
    SELECT COUNT(*) AS RemainingRows FROM GriddedDataStaging
END

-- Check if GriddedData table exists
SELECT CASE 
    WHEN OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL THEN 'GriddedData table exists'
    ELSE 'GriddedData table does not exist'
END AS GriddedData_Status

-- Get GriddedData statistics if it exists
IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    SELECT COUNT(*) AS TotalRows,
           COUNT(DISTINCT RowID) AS UniqueRows,
           COUNT(DISTINCT ColumnID) AS UniqueColumns,
           AVG(Value) AS AverageValue,
           MIN(Value) AS MinValue,
           MAX(Value) AS MaxValue
    FROM GriddedData

    -- Sample data from GriddedData
    SELECT TOP 5 * FROM GriddedData
END
