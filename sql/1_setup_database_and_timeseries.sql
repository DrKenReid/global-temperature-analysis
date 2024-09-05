-- 1_setup_database_and_timeseries.sql
USE [$(SQL_DATABASE_NAME)]

SET NOCOUNT ON

PRINT 'Starting database setup and TimeSeries table creation...'

-- Create a table for the time series data if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeSeries]') AND type = N'U')
BEGIN
    PRINT 'Creating TimeSeries table...'
    CREATE TABLE TimeSeries (
        Year INT NOT NULL,
        Temperature FLOAT NOT NULL,
        V3 FLOAT,
        V4 FLOAT,
        V5 FLOAT,
        V6 FLOAT,
        V7 VARCHAR(50),
        V8 VARCHAR(50),
        V9 VARCHAR(50),
        V10 VARCHAR(50),
        CONSTRAINT PK_TimeSeries PRIMARY KEY CLUSTERED (Year)
    )
    PRINT 'TimeSeries table created successfully.'
END
ELSE
BEGIN
    PRINT 'TimeSeries table already exists.'
END

-- Check if data exists in the TimeSeries table
IF NOT EXISTS (SELECT TOP 1 * FROM TimeSeries)
BEGIN
    PRINT 'TimeSeries table is empty. Attempting to import data...'
    
    -- Import data from CSV file using BULK INSERT
    DECLARE @BulkInsertSQL NVARCHAR(MAX)
    DECLARE @CSVPath NVARCHAR(255) = '..\data\raw\combined_time_series.csv'
    
    PRINT 'CSV Path: ' + @CSVPath
    
    IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeSeries]') AND type = N'U')
    BEGIN
        PRINT 'Error: TimeSeries table does not exist.'
        RETURN
    END
    
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[TimeSeries]'))
    BEGIN
        PRINT 'Error: TimeSeries table has no columns.'
        RETURN
    END
    
    SET @BulkInsertSQL = 'BULK INSERT TimeSeries
    FROM ''' + @CSVPath + '''
    WITH (
        FORMAT = ''CSV'',
        FIRSTROW = 2,
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\n'',
        TABLOCK
    )'
    
    PRINT 'Executing BULK INSERT with SQL: ' + @BulkInsertSQL
    
    BEGIN TRY
        EXEC sp_executesql @BulkInsertSQL
        PRINT 'Data imported successfully into TimeSeries table.'
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while importing data:'
        PRINT ERROR_MESSAGE()
    END CATCH
END
ELSE
BEGIN
    PRINT 'TimeSeries table already contains data.'
END

-- Print some statistics about the TimeSeries table
PRINT 'TimeSeries table statistics:'
SELECT 
    'Total Rows' = COUNT(*),
    'Min Year' = MIN(Year),
    'Max Year' = MAX(Year),
    'Avg Temperature' = AVG(Temperature)
FROM TimeSeries
