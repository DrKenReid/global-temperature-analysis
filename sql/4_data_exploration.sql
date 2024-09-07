-- 4_data_exploration.sql
USE GlobalTemperatureAnalysis

SET NOCOUNT ON

PRINT 'Starting data exploration...'

-- Create a table to store exploration results if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExplorationResults]') AND type = N'U')
BEGIN
    CREATE TABLE ExplorationResults (
        ResultID INT IDENTITY(1,1) PRIMARY KEY,
        ExplorationName NVARCHAR(100),
        ResultData NVARCHAR(MAX),
        CreatedAt DATETIME DEFAULT GETDATE()
    )
    PRINT 'ExplorationResults table created.'
END

-- Function to insert exploration results
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsertExplorationResult]') AND type IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
    EXEC('
    CREATE FUNCTION dbo.InsertExplorationResult
    (
        @ExplorationName NVARCHAR(100),
        @ResultData NVARCHAR(MAX)
    )
    RETURNS INT
    AS
    BEGIN
        DECLARE @ResultID INT

        INSERT INTO ExplorationResults (ExplorationName, ResultData)
        VALUES (@ExplorationName, @ResultData)

        SET @ResultID = SCOPE_IDENTITY()

        RETURN @ResultID
    END
    ')
    PRINT 'InsertExplorationResult function created.'
END

-- Explore TimeSeries data
PRINT 'TimeSeries Data Summary:'
DECLARE @TimeSeriesSummary NVARCHAR(MAX)
SET @TimeSeriesSummary = (
    SELECT 
        COUNT(*) AS TotalRecords,
        MIN(Year) AS EarliestYear,
        MAX(Year) AS LatestYear,
        AVG(Temperature) AS AverageTemperature,
        MIN(Temperature) AS MinTemperature,
        MAX(Temperature) AS MaxTemperature
    FROM TimeSeries
    FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
)
PRINT @TimeSeriesSummary
EXEC dbo.InsertExplorationResult 'TimeSeries Summary', @TimeSeriesSummary

-- Temperature trend by decade
PRINT 'Temperature Trend by Decade:'
DECLARE @TemperatureTrend NVARCHAR(MAX)
SET @TemperatureTrend = (
    SELECT 
        CONCAT(FLOOR(Year / 10) * 10, 's') AS Decade,
        AVG(Temperature) AS AverageTemperature
    FROM TimeSeries
    GROUP BY FLOOR(Year / 10)
    ORDER BY Decade
    FOR JSON AUTO
)
PRINT @TemperatureTrend
EXEC dbo.InsertExplorationResult 'Temperature Trend by Decade', @TemperatureTrend

-- Explore GriddedData
PRINT 'GriddedData Summary:'
DECLARE @GriddedDataSummary NVARCHAR(MAX)
SET @GriddedDataSummary = (
    SELECT 
        COUNT(*) AS TotalRecords,
        COUNT(DISTINCT RowID) AS UniqueYears,
        COUNT(DISTINCT ColumnID) AS GridPoints,
        AVG(Value) AS AverageValue,
        MIN(Value) AS MinValue,
        MAX(Value) AS MaxValue
    FROM GriddedData
    FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
)
PRINT @GriddedDataSummary
EXEC dbo.InsertExplorationResult 'GriddedData Summary', @GriddedDataSummary

-- Top 5 hottest and coldest points
PRINT 'Top 5 Hottest Points:'
DECLARE @HottestPoints NVARCHAR(MAX)
SET @HottestPoints = (
    SELECT TOP 5 RowID, ColumnID, Value
    FROM GriddedData
    ORDER BY Value DESC
    FOR JSON AUTO
)
PRINT @HottestPoints
EXEC dbo.InsertExplorationResult 'Top 5 Hottest Points', @HottestPoints

PRINT 'Top 5 Coldest Points:'
DECLARE @ColdestPoints NVARCHAR(MAX)
SET @ColdestPoints = (
    SELECT TOP 5 RowID, ColumnID, Value
    FROM GriddedData
    ORDER BY Value ASC
    FOR JSON AUTO
)
PRINT @ColdestPoints
EXEC dbo.InsertExplorationResult 'Top 5 Coldest Points', @ColdestPoints

-- Distribution of temperature values
PRINT 'Temperature Distribution:'
DECLARE @TemperatureDistribution NVARCHAR(MAX)
SET @TemperatureDistribution = (
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
    FOR JSON AUTO
)
PRINT @TemperatureDistribution
EXEC dbo.InsertExplorationResult 'Temperature Distribution', @TemperatureDistribution

PRINT 'Data exploration completed. Results stored in ExplorationResults table.'

-- Display stored results
SELECT * FROM ExplorationResults
