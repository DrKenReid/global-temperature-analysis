-- sql_operations.sql

-- Switch to master database to create a new database
USE master;
GO

-- Create the GlobalTemperatureAnalysis database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'GlobalTemperatureAnalysis')
BEGIN
    CREATE DATABASE GlobalTemperatureAnalysis;
    PRINT 'GlobalTemperatureAnalysis database created.'
END
ELSE
    PRINT 'GlobalTemperatureAnalysis database already exists.'
GO

-- Switch to the GlobalTemperatureAnalysis database
USE GlobalTemperatureAnalysis;
GO

-- Create a table for the time series data if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeSeries]') AND type in (N'U'))
BEGIN
    CREATE TABLE TimeSeries (
        Year INT NOT NULL,  -- NOT NULL constraint added
        Temperature FLOAT NOT NULL,  -- NOT NULL constraint added
        V3 FLOAT,
        V4 FLOAT,
        V5 FLOAT,
        V6 FLOAT,
        V7 VARCHAR(50),
        V8 VARCHAR(50),
        V9 VARCHAR(50),
        V10 VARCHAR(50),
        CONSTRAINT PK_TimeSeries PRIMARY KEY CLUSTERED (Year)  -- Primary key added
    );
    PRINT 'TimeSeries table created.'
END
ELSE
    PRINT 'TimeSeries table already exists.'

-- Import data from CSV file using BULK INSERT
-- Note: Ensure the file path is correct and the SQL Server service account has access to this location
PRINT 'Starting BULK INSERT operation for TimeSeries...'
BULK INSERT TimeSeries
FROM 'C:\Users\Ken\temperature-analysis-project\data\raw\combined_time_series.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    TABLOCK  -- Added for improved performance
);
PRINT 'BULK INSERT operation for TimeSeries completed.'

-- Verify the data
PRINT 'Verifying TimeSeries data:'
SELECT TOP 10 * FROM TimeSeries;

-- Prepare for GriddedData import
PRINT 'Preparing for GriddedData import...'

-- Drop the existing GriddedData table if it exists
IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.GriddedData;
    PRINT 'Existing GriddedData table dropped.'
END

-- Create a staging table for GriddedData
CREATE TABLE GriddedDataStaging (
    RowID INT IDENTITY(1,1) PRIMARY KEY,
    RawData NVARCHAR(MAX)
);
PRINT 'GriddedDataStaging table created.'

-- Create indexes to improve query performance
CREATE NONCLUSTERED INDEX IX_TimeSeries_Temperature ON TimeSeries(Temperature);
PRINT 'Index created on TimeSeries(Temperature).'

-- Add a clustered columnstore index on GriddedDataStaging for better compression and query performance
-- Note: This is beneficial for large datasets, but might slow down initial data loading
CREATE CLUSTERED COLUMNSTORE INDEX CCI_GriddedDataStaging ON GriddedDataStaging;
PRINT 'Clustered columnstore index created on GriddedDataStaging.'

PRINT 'SQL operations completed successfully.'