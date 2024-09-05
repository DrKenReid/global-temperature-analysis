-- verify_data_processing.sql
USE GlobalTemperatureAnalysis

SET NOCOUNT ON

PRINT '--- Data Processing Verification Report ---'

-- Check TimeSeries table
PRINT 'Verifying TimeSeries table:'
IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL
BEGIN
    SELECT TOP 10 * FROM TimeSeries
    
    SELECT 
        COUNT(*) as TotalRows, 
        MIN(Year) as MinYear, 
        MAX(Year) as MaxYear,
        AVG(Temperature) as AvgTemperature
    FROM TimeSeries
END
ELSE
    PRINT 'TimeSeries table does not exist.'

-- Check GriddedData table
PRINT 'Verifying GriddedData table:'
IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    SELECT TOP 10 * FROM GriddedData
    
    SELECT 
        COUNT(*) AS TotalRows,
        COUNT(DISTINCT RowID) AS UniqueRows,
        COUNT(DISTINCT ColumnID) AS UniqueColumns,
        AVG(Value) AS AverageValue,
        MIN(Value) AS MinValue,
        MAX(Value) AS MaxValue
    FROM GriddedData
END
ELSE
    PRINT 'GriddedData table does not exist.'

-- Verify data consistency between TimeSeries and GriddedData
PRINT 'Verifying data consistency:'
IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL AND OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    SELECT 
        t.Year, 
        t.Temperature AS TimeSeriesTemp, 
        g.AvgGriddedTemp,
        ABS(t.Temperature - g.AvgGriddedTemp) AS Difference
    FROM TimeSeries t
    LEFT JOIN (
        SELECT RowID, AVG(Value) AS AvgGriddedTemp
        FROM GriddedData
        GROUP BY RowID
    ) g ON t.Year = g.RowID
    WHERE ABS(t.Temperature - g.AvgGriddedTemp) > 0.1  -- Adjust threshold as needed
END

PRINT '--- End of Data Processing Verification Report ---'
