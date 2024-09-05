-- 4_data_exploration.sql
USE GlobalTemperatureAnalysis

SET NOCOUNT ON

PRINT 'Starting data exploration...'

-- Explore TimeSeries data
PRINT 'TimeSeries Data Summary:'
SELECT 
    COUNT(*) AS TotalRecords,
    MIN(Year) AS EarliestYear,
    MAX(Year) AS LatestYear,
    AVG(Temperature) AS AverageTemperature,
    MIN(Temperature) AS MinTemperature,
    MAX(Temperature) AS MaxTemperature
FROM TimeSeries

-- Temperature trend by decade
PRINT 'Temperature Trend by Decade:'
SELECT 
    CONCAT(FLOOR(Year / 10) * 10, 's') AS Decade,
    AVG(Temperature) AS AverageTemperature
FROM TimeSeries
GROUP BY FLOOR(Year / 10)
ORDER BY Decade

-- Explore GriddedData
PRINT 'GriddedData Summary:'
SELECT 
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT RowID) AS UniqueYears,
    COUNT(DISTINCT ColumnID) AS GridPoints,
    AVG(Value) AS AverageValue,
    MIN(Value) AS MinValue,
    MAX(Value) AS MaxValue
FROM GriddedData

-- Top 5 hottest and coldest points
PRINT 'Top 5 Hottest Points:'
SELECT TOP 5 RowID, ColumnID, Value
FROM GriddedData
ORDER BY Value DESC

PRINT 'Top 5 Coldest Points:'
SELECT TOP 5 RowID, ColumnID, Value
FROM GriddedData
ORDER BY Value ASC

-- Distribution of temperature values
PRINT 'Temperature Distribution:'
SELECT 
    TempCategory,
    COUNT(*) AS Count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM GriddedData) AS Percentage
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
    END

PRINT 'Data exploration completed.'
