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
    DECLARE @CSVPath NVARCHAR(255) = '$(CSV_PATH)'
    
    PRINT 'CSV Path: ' + @CSVPath
    
    -- Check if the CSV file exists
    IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'xp_fileexist'))
    BEGIN
        PRINT 'Error: xp_fileexist stored procedure is not available.'
        RETURN
    END
    
    DECLARE @FileExists INT
    EXEC master.dbo.xp_fileexist @CSVPath, @FileExists OUTPUT
    
    IF @FileExists = 0
    BEGIN
        PRINT 'Error: CSV file does not exist at path: ' + @CSVPath
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
        
        -- Check the number of rows imported
        DECLARE @RowCount INT
        SELECT @RowCount = COUNT(*) FROM TimeSeries
        PRINT 'Data imported successfully into TimeSeries table. Rows imported: ' + CAST(@RowCount AS NVARCHAR(20))
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while importing data:'
        PRINT ERROR_MESSAGE()
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10))
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10))
        PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(10))
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(10))
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
