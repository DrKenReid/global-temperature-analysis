USE GlobalTemperatureAnalysis

-- =============================================
-- Author:      Ken Reid
-- Create date: 2024-09-18
-- Description: Script to drop all related tables in the GlobalTemperatureAnalysis database
-- =============================================

SET NOCOUNT ON;

BEGIN TRY
    -- Begin a transaction to ensure atomicity
    BEGIN TRANSACTION;

    -- Disable foreign key constraints
    EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
    PRINT 'Disabled all foreign key constraints.';

    -- List of tables to drop
    DECLARE @tablesToDrop TABLE (TableName NVARCHAR(128));
    INSERT INTO @tablesToDrop (TableName)
    VALUES 
        ('dbo.ProcessedGriddedData'),
        ('dbo.ProcessedTimeSeries'),
        ('dbo.GriddedDataStaging'),
        ('dbo.GriddedData'),
        ('dbo.TimeSeries'),
        ('dbo.ExplorationResults');

    -- Drop tables if they exist
    DECLARE @sql NVARCHAR(MAX);
    SELECT @sql = STRING_AGG('
    IF OBJECT_ID(''' + TableName + ''', ''U'') IS NOT NULL
    BEGIN
        DROP TABLE ' + TableName + ';
        PRINT ''Dropped table ' + TableName + '.''; 
    END
    ELSE
    BEGIN
        PRINT ''Table ' + TableName + ' does not exist.'';
    END', CHAR(13))
    FROM @tablesToDrop;

    EXEC sp_executesql @sql;

    -- Re-enable foreign key constraints
    EXEC sp_msforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
    PRINT 'Re-enabled all foreign key constraints.';

    -- Commit the transaction
    COMMIT TRANSACTION;
    PRINT 'All related tables have been dropped successfully.';
END TRY
BEGIN CATCH
    -- Rollback the transaction in case of an error
    ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
