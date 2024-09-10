USE [$(SQL_DATABASE_NAME)]
SET NOCOUNT ON

PRINT '--- Data Processing Verification Report ---'

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

PRINT '--- End of Data Processing Verification Report ---'
