-- 6_verify_data_exploration.sql
USE GlobalTemperatureAnalysis

SET NOCOUNT ON

PRINT 'Verifying data exploration results...'

-- Verify TimeSeries data
PRINT 'TimeSeries Data Summary:'
IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL
BEGIN
    SELECT 
        COUNT(*) AS TotalRecords,
        MIN(Year) AS EarliestYear,
        MAX(Year) AS LatestYear,
        ROUND(AVG(Temperature), 4) AS AverageTemperature,
        ROUND(MIN(Temperature), 4) AS MinTemperature,
        ROUND(MAX(Temperature), 4) AS MaxTemperature
    FROM TimeSeries;
END
ELSE
    SELECT 'TimeSeries table does not exist.' AS Message;

-- Verify Temperature trend by decade
PRINT 'Temperature Trend by Decade (Top 5):'
IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL
BEGIN
    SELECT TOP 5
        Decade,
        ROUND(AverageTemperature, 4) AS AverageTemperature
    FROM (
        SELECT 
            CONCAT(FLOOR(Year / 10) * 10, 's') AS Decade,
            AVG(Temperature) AS AverageTemperature
        FROM TimeSeries
        GROUP BY FLOOR(Year / 10)
    ) AS DecadeTrend
    ORDER BY AverageTemperature DESC;
END
ELSE
    SELECT 'TimeSeries table does not exist.' AS Message;

-- Verify GriddedData
PRINT 'GriddedData Summary:'
IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    SELECT 
        COUNT(*) AS TotalRecords,
        COUNT(DISTINCT RowID) AS UniqueYears,
        COUNT(DISTINCT ColumnID) AS GridPoints,
        ROUND(AVG(Value), 4) AS AverageValue,
        ROUND(MIN(Value), 4) AS MinValue,
        ROUND(MAX(Value), 4) AS MaxValue
    FROM GriddedData;
END
ELSE
    SELECT 'GriddedData table does not exist.' AS Message;

-- Verify Top 5 hottest points
PRINT 'Top 5 Hottest Points:'
IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    SELECT TOP 5 
        RowID, 
        ColumnID, 
        ROUND(Value, 4) AS Value
    FROM GriddedData
    ORDER BY Value DESC;
END
ELSE
    SELECT 'GriddedData table does not exist.' AS Message;

-- Verify Temperature Distribution
PRINT 'Temperature Distribution Summary:'
IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    SELECT 
        TempCategory,
        COUNT(*) AS Count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM GriddedData), 2) AS Percentage
    FROM (
        SELECT 
            CASE 
                WHEN Value < -2 THEN 'Extremely Cold'
                WHEN Value >= -2 AND Value < -1 THEN 'Very Cold'
                WHEN Value >= -1 AND Value < 0 THEN 'Cold'
                WHEN Value >= 0 AND Value < 1 THEN 'Warm'
                WHEN Value >= 1 AND Value < 2 THEN 'Very Warm'
                ELSE 'Extremely Warm'
            END AS TempCategory
        FROM GriddedData
    ) AS TempCategorization
    GROUP BY TempCategory
    ORDER BY 
        CASE TempCategory
            WHEN 'Extremely Cold' THEN 1
            WHEN 'Very Cold' THEN 2
            WHEN 'Cold' THEN 3
            WHEN 'Warm' THEN 4
            WHEN 'Very Warm' THEN 5
            WHEN 'Extremely Warm' THEN 6
        END;
END
ELSE
    SELECT 'GriddedData table does not exist.' AS Message;

PRINT 'Data exploration verification completed.'
