USE [$(SQL_DATABASE_NAME)];

-- =============================================
-- Author:      Ken Reid
-- Create date: 2024-09-15
-- Description: Script to explore processed data for insights
-- =============================================

SET NOCOUNT ON;

-- Check if required tables exist
IF OBJECT_ID('dbo.ProcessedTimeSeries', 'U') IS NULL 
    OR OBJECT_ID('dbo.ProcessedGriddedData', 'U') IS NULL
BEGIN
    RAISERROR ('Required tables do not exist. Please ensure data processing step completed successfully.', 16, 1);
    RETURN;
END

-- Global temperature trends
SELECT TOP 10 
    Year, 
    AverageTemperature, 
    TenYearMovingAverage
FROM dbo.ProcessedTimeSeries
ORDER BY Year ASC;

-- Hottest years on record
SELECT TOP 10 
    Year, 
    AverageTemperature
FROM dbo.ProcessedTimeSeries
ORDER BY AverageTemperature DESC;

-- Coldest years on record
SELECT TOP 10 
    Year, 
    AverageTemperature
FROM dbo.ProcessedTimeSeries
ORDER BY AverageTemperature ASC;

-- Temperature change by latitude band
;WITH LatitudeBands AS (
    SELECT
        CASE
            WHEN Latitude BETWEEN -90 AND -60 THEN 'Antarctic'
            WHEN Latitude BETWEEN -60 AND -23.5 THEN 'Southern Temperate'
            WHEN Latitude BETWEEN -23.5 AND 23.5 THEN 'Tropical'
            WHEN Latitude BETWEEN 23.5 AND 60 THEN 'Northern Temperate'
            WHEN Latitude BETWEEN 60 AND 90 THEN 'Arctic'
        END AS LatitudeBand,
        Year,
        AverageTemperature
    FROM dbo.ProcessedGriddedData
),
BandAverages AS (
    SELECT
        LatitudeBand,
        Year,
        AVG(AverageTemperature) AS AvgTemperature
    FROM LatitudeBands
    GROUP BY LatitudeBand, Year
),
StartEndTemperatures AS (
    SELECT DISTINCT
        LatitudeBand,
        FIRST_VALUE(Year) OVER (PARTITION BY LatitudeBand ORDER BY Year ASC) AS StartYear,
        LAST_VALUE(Year) OVER (PARTITION BY LatitudeBand ORDER BY Year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS EndYear,
        FIRST_VALUE(AvgTemperature) OVER (PARTITION BY LatitudeBand ORDER BY Year ASC) AS StartTemperature,
        LAST_VALUE(AvgTemperature) OVER (PARTITION BY LatitudeBand ORDER BY Year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS EndTemperature
    FROM BandAverages
)
SELECT
    LatitudeBand,
    StartYear,
    EndYear,
    StartTemperature,
    EndTemperature,
    EndTemperature - StartTemperature AS TemperatureChange
FROM StartEndTemperatures
ORDER BY TemperatureChange DESC;

-- Global average temperature change
;WITH GlobalTemps AS (
    SELECT
        MIN(Year) OVER () AS StartYear,
        MAX(Year) OVER () AS EndYear,
        FIRST_VALUE(AverageTemperature) OVER (ORDER BY Year ASC) AS StartTemperature,
        LAST_VALUE(AverageTemperature) OVER (ORDER BY Year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS EndTemperature
    FROM dbo.ProcessedTimeSeries
)
SELECT DISTINCT
    StartYear,
    EndYear,
    StartTemperature,
    EndTemperature,
    EndTemperature - StartTemperature AS TemperatureChange
FROM GlobalTemps;
