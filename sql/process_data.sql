USE [$(SQL_DATABASE_NAME)];

-- =============================================
-- Author:      Ken Reid
-- Create date: 2024-09-15
-- Description: Script to process raw data into processed tables
-- =============================================

SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Drop and recreate ProcessedGriddedData table
    IF OBJECT_ID('dbo.ProcessedGriddedData', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.ProcessedGriddedData;
        PRINT 'Dropped existing table dbo.ProcessedGriddedData.';
    END

    CREATE TABLE dbo.ProcessedGriddedData (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Year INT NOT NULL,
        Latitude FLOAT NOT NULL,
        Longitude FLOAT NOT NULL,
        AverageTemperature FLOAT NOT NULL
    );
    PRINT 'Created table dbo.ProcessedGriddedData.';

    -- Insert aggregated data into ProcessedGriddedData
    INSERT INTO dbo.ProcessedGriddedData (Year, Latitude, Longitude, AverageTemperature)
    SELECT 
        DATEPART(YEAR, DATEADD(DAY, Time, '1850-01-01')) AS Year,
        Latitude,
        Longitude,
        AVG(Temperature) AS AverageTemperature
    FROM 
        dbo.GriddedData
    GROUP BY 
        DATEPART(YEAR, DATEADD(DAY, Time, '1850-01-01')),
        Latitude,
        Longitude;
    PRINT 'Inserted data into dbo.ProcessedGriddedData.';

    -- Drop and recreate ProcessedTimeSeries table
    IF OBJECT_ID('dbo.ProcessedTimeSeries', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.ProcessedTimeSeries;
        PRINT 'Dropped existing table dbo.ProcessedTimeSeries.';
    END

    CREATE TABLE dbo.ProcessedTimeSeries (
        Year INT PRIMARY KEY,
        AverageTemperature FLOAT NOT NULL,
        TenYearMovingAverage FLOAT NULL
    );
    PRINT 'Created table dbo.ProcessedTimeSeries.';

    -- Insert data into ProcessedTimeSeries
    INSERT INTO dbo.ProcessedTimeSeries (Year, AverageTemperature)
    SELECT Year, Temperature
    FROM dbo.TimeSeries;
    PRINT 'Inserted data into dbo.ProcessedTimeSeries.';

    -- Calculate 10-year moving average
    ;WITH MovingAvg AS (
        SELECT 
            Year, 
            AverageTemperature,
            AVG(AverageTemperature) OVER (
                ORDER BY Year 
                ROWS BETWEEN 4 PRECEDING AND 5 FOLLOWING
            ) AS TenYearMovingAverage
        FROM dbo.ProcessedTimeSeries
    )
    UPDATE pt
    SET TenYearMovingAverage = ma.TenYearMovingAverage
    FROM dbo.ProcessedTimeSeries pt
    INNER JOIN MovingAvg ma ON pt.Year = ma.Year;
    PRINT 'Calculated TenYearMovingAverage in dbo.ProcessedTimeSeries.';

    COMMIT TRANSACTION;
    PRINT 'Data processing completed successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
