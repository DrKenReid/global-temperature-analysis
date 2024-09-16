USE [$(SQL_DATABASE_NAME)];

-- =============================================
-- Author:      Ken Reid
-- Create date: 2024-09-15
-- Description: Script to perform diagnostics on processed data
-- =============================================

SET NOCOUNT ON;

BEGIN TRY
    -- Diagnostics on ProcessedGriddedData
    SELECT 
        COUNT(*) AS TotalRows,
        MIN(Year) AS MinYear,
        MAX(Year) AS MaxYear,
        MIN(Latitude) AS MinLatitude,
        MAX(Latitude) AS MaxLatitude,
        MIN(Longitude) AS MinLongitude,
        MAX(Longitude) AS MaxLongitude,
        AVG(AverageTemperature) AS OverallAverageTemperature
    FROM dbo.ProcessedGriddedData;

    -- Diagnostics on ProcessedTimeSeries
    SELECT 
        COUNT(*) AS TotalRows,
        MIN(Year) AS MinYear,
        MAX(Year) AS MaxYear,
        AVG(AverageTemperature) AS OverallAverageTemperature,
        AVG(TenYearMovingAverage) AS AverageTenYearMovingAverage
    FROM dbo.ProcessedTimeSeries;

    -- Check for missing years in ProcessedTimeSeries
    ;WITH AllYears AS (
        SELECT 
            MIN(Year) AS StartYear,
            MAX(Year) AS EndYear
        FROM dbo.ProcessedTimeSeries
    ),
    YearRange AS (
        SELECT TOP ((SELECT EndYear - StartYear + 1 FROM AllYears))
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT StartYear - 1 FROM AllYears) AS Year
        FROM sys.all_objects
    )
    SELECT 
        y.Year AS MissingYear
    FROM YearRange y
    LEFT JOIN dbo.ProcessedTimeSeries p ON y.Year = p.Year
    WHERE p.Year IS NULL
    ORDER BY y.Year;
END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;

