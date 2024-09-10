USE GlobalTemperatureAnalysis;

-- Run diagnostics on ProcessedGriddedData
SELECT 
    COUNT(*) AS TotalRows,
    MIN(Year) AS MinYear,
    MAX(Year) AS MaxYear,
    MIN(Latitude) AS MinLatitude,
    MAX(Latitude) AS MaxLatitude,
    MIN(Longitude) AS MinLongitude,
    MAX(Longitude) AS MaxLongitude,
    AVG(AverageTemperature) AS OverallAverageTemperature
FROM 
    dbo.ProcessedGriddedData;

-- Run diagnostics on ProcessedTimeSeries
SELECT 
    COUNT(*) AS TotalRows,
    MIN(Year) AS MinYear,
    MAX(Year) AS MaxYear,
    AVG(AverageTemperature) AS OverallAverageTemperature,
    AVG(TenYearMovingAverage) AS AverageTenYearMovingAverage
FROM 
    dbo.ProcessedTimeSeries;

-- Check for missing years in ProcessedTimeSeries
;WITH AllYears AS (
    SELECT TOP (SELECT MAX(Year) - MIN(Year) + 1 FROM dbo.ProcessedTimeSeries)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT MIN(Year) - 1 FROM dbo.ProcessedTimeSeries) AS Year
    FROM master.dbo.spt_values
)
SELECT 
    a.Year AS MissingYear
FROM 
    AllYears a
LEFT JOIN 
    dbo.ProcessedTimeSeries p ON a.Year = p.Year
WHERE 
    p.Year IS NULL
ORDER BY 
    a.Year;
