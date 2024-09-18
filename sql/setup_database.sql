USE [$(SQL_DATABASE_NAME)];

-- =============================================
-- Author:      Ken Reid
-- Create date: 2024-09-15
-- Description: Script to set up initial database schema
-- =============================================

SET NOCOUNT ON;

ALTER TABLE dbo.TimeSeries NOCHECK CONSTRAINT ALL;
DELETE FROM dbo.TimeSeries;
ALTER TABLE dbo.TimeSeries CHECK CONSTRAINT ALL;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Drop and recreate TimeSeries table
    IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.TimeSeries;
        PRINT 'Dropped existing table dbo.TimeSeries.';
    END

    CREATE TABLE dbo.TimeSeries (
        Year INT NOT NULL PRIMARY KEY,
        Temperature FLOAT NOT NULL
    );
    PRINT 'Created table dbo.TimeSeries.';

    -- Drop and recreate GriddedData table
    IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.GriddedData;
        PRINT 'Dropped existing table dbo.GriddedData.';
    END

    CREATE TABLE dbo.GriddedData (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Longitude FLOAT NOT NULL,
        Latitude FLOAT NOT NULL,
        Time FLOAT NOT NULL,
        Temperature FLOAT NOT NULL
    );
    PRINT 'Created table dbo.GriddedData.';

    -- Create ExplorationResults table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ExplorationResults' AND type = 'U')
    BEGIN
        CREATE TABLE dbo.ExplorationResults (
            ID INT IDENTITY(1,1) PRIMARY KEY,
            AnalysisName NVARCHAR(100) NOT NULL,
            Result NVARCHAR(MAX) NOT NULL
        );
        PRINT 'Created table dbo.ExplorationResults.';
    END

    -- Commit transaction if all statements succeed
    COMMIT TRANSACTION;
    PRINT 'Database setup completed successfully.';
END TRY
BEGIN CATCH
    -- Rollback transaction if any statement fails
    ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
