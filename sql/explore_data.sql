USE GlobalTemperatureAnalysis;

-- Check if tables exist
IF OBJECT_ID('dbo.ProcessedTimeSeries', 'U') IS NULL OR OBJECT_ID('dbo.ProcessedGriddedData', 'U') IS NULL
BEGIN
    RAISERROR ('Required tables do not exist. Please ensure data processing step completed successfully.', 16, 1)
    RETURN
END

-- Global temperature trends
SELECT TOP 10 Year, AverageTemperature, TenYearMovingAverage
FROM dbo.ProcessedTimeSeries
ORDER BY Year;

-- Hottest years
SELECT TOP 10 Year, AverageTemperature
FROM dbo.ProcessedTimeSeries
ORDER BY AverageTemperature DESC;

-- Coldest years
SELECT TOP 10 Year, AverageTemperature
FROM dbo.ProcessedTimeSeries
ORDER BY AverageTemperature ASC;

-- Temperature change by latitude
;WITH LatitudeBands AS (
    SELECT
        CASE
            WHEN Latitude BETWEEN -90 AND -60 THEN 'Antarctic'
            WHEN Latitude BETWEEN -60 AND -23 THEN 'Southern Temperate'
            WHEN Latitude BETWEEN -23 AND 23 THEN 'Tropical'
            WHEN Latitude BETWEEN 23 AND 60 THEN 'Northern Temperate'
            WHEN Latitude BETWEEN 60 AND 90 THEN 'Arctic'
        END AS LatitudeBand,
        Year,
        AVG(AverageTemperature) AS AvgTemperature
    FROM
        dbo.ProcessedGriddedData
    GROUP BY
        CASE
            WHEN Latitude BETWEEN -90 AND -60 THEN 'Antarctic'
            WHEN Latitude BETWEEN -60 AND -23 THEN 'Southern Temperate'
            WHEN Latitude BETWEEN -23 AND 23 THEN 'Tropical'
            WHEN Latitude BETWEEN 23 AND 60 THEN 'Northern Temperate'
            WHEN Latitude BETWEEN 60 AND 90 THEN 'Arctic'
        END,
        Year
),
StartEndTemperatures AS (
    SELECT
        LatitudeBand,
        MIN(Year) AS StartYear,
        MAX(Year) AS EndYear
    FROM LatitudeBands
    GROUP BY LatitudeBand
),
LatitudeBandStats AS (
    SELECT
        lb.LatitudeBand,
        se.StartYear,
        se.EndYear,
        (SELECT AVG(AvgTemperature) FROM LatitudeBands lb2 WHERE lb2.LatitudeBand = lb.LatitudeBand AND lb2.Year = se.StartYear) AS StartTemperature,
        (SELECT AVG(AvgTemperature) FROM LatitudeBands lb2 WHERE lb2.LatitudeBand = lb.LatitudeBand AND lb2.Year = se.EndYear) AS EndTemperature
    FROM LatitudeBands lb
    INNER JOIN StartEndTemperatures se ON lb.LatitudeBand = se.LatitudeBand
)
SELECT
    LatitudeBand,
    StartYear,
    EndYear,
    StartTemperature,
    EndTemperature,
    EndTemperature - StartTemperature AS TemperatureChange
FROM LatitudeBandStats
ORDER BY TemperatureChange DESC;

-- Global average temperature change
;WITH GlobalStats AS (
    SELECT
        MIN(Year) AS StartYear,
        MAX(Year) AS EndYear
    FROM dbo.ProcessedTimeSeries
),
StartEndTemperatures AS (
    SELECT
        (SELECT AVG(AverageTemperature) FROM dbo.ProcessedTimeSeries WHERE Year = (SELECT MIN(Year) FROM dbo.ProcessedTimeSeries)) AS StartTemperature,
        (SELECT AVG(AverageTemperature) FROM dbo.ProcessedTimeSeries WHERE Year = (SELECT MAX(Year) FROM dbo.ProcessedTimeSeries)) AS EndTemperature
)
SELECT
    gs.StartYear,
    gs.EndYear,
    se.StartTemperature,
    se.EndTemperature,
    se.EndTemperature - se.StartTemperature AS TemperatureChange
FROM GlobalStats gs
CROSS JOIN StartEndTemperatures se;
