-- Drop all related tables in the Global Temperature Analysis database

-- Disable foreign key checks to allow dropping tables in any order
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

-- Drop the main data tables
IF OBJECT_ID('dbo.TimeSeries', 'U') IS NOT NULL
    DROP TABLE dbo.TimeSeries;

IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
    DROP TABLE dbo.GriddedData;

IF OBJECT_ID('dbo.ProcessedTimeSeries', 'U') IS NOT NULL
    DROP TABLE dbo.ProcessedTimeSeries;

IF OBJECT_ID('dbo.ProcessedGriddedData', 'U') IS NOT NULL
    DROP TABLE dbo.ProcessedGriddedData;

-- Drop the results table
IF OBJECT_ID('dbo.ExplorationResults', 'U') IS NOT NULL
    DROP TABLE dbo.ExplorationResults;

-- Drop any staging tables that might exist
IF OBJECT_ID('dbo.GriddedDataStaging', 'U') IS NOT NULL
    DROP TABLE dbo.GriddedDataStaging;

-- Re-enable foreign key checks
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"

-- Print completion message
PRINT 'All related tables have been dropped successfully.';
