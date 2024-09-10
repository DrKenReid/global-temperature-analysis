USE GlobalTemperatureAnalysis;

-- Process GriddedData
IF OBJECT_ID('dbo.ProcessedGriddedData', 'U') IS NOT NULL
    DROP TABLE dbo.ProcessedGriddedData;

CREATE TABLE dbo.ProcessedGriddedData (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Year INT,
    Latitude FLOAT,
    Longitude FLOAT,
    AverageTemperature FLOAT
);

INSERT INTO dbo.ProcessedGriddedData (Year, Latitude, Longitude, AverageTemperature)
SELECT 
    YEAR(DATEADD(DAY, Time, '1850-01-01')) AS Year,
    Latitude,
    Longitude,
    AVG(Temperature) AS AverageTemperature
FROM 
    dbo.GriddedData
GROUP BY 
    YEAR(DATEADD(DAY, Time, '1850-01-01')),
    Latitude,
    Longitude;

-- Process TimeSeries
IF OBJECT_ID('dbo.ProcessedTimeSeries', 'U') IS NOT NULL
    DROP TABLE dbo.ProcessedTimeSeries;

CREATE TABLE dbo.ProcessedTimeSeries (
    Year INT PRIMARY KEY,
    AverageTemperature FLOAT,
    TenYearMovingAverage FLOAT
);

INSERT INTO dbo.ProcessedTimeSeries (Year, AverageTemperature)
SELECT Year, Temperature
FROM dbo.TimeSeries;

-- Calculate 10-year moving average
;WITH CTE AS (
    SELECT 
        Year, 
        AverageTemperature,
        AVG(AverageTemperature) OVER (ORDER BY Year ROWS BETWEEN 4 PRECEDING AND 5 FOLLOWING) AS TenYearMovingAverage
    FROM 
        dbo.ProcessedTimeSeries
)
UPDATE dbo.ProcessedTimeSeries
SET TenYearMovingAverage = CTE.TenYearMovingAverage
FROM CTE
WHERE dbo.ProcessedTimeSeries.Year = CTE.Year;
