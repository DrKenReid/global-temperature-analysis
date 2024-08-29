-- 1_setup_database_and_timeseries.sql
-- Create the GlobalTemperatureAnalysis database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'GlobalTemperatureAnalysis')
BEGIN
    CREATE DATABASE GlobalTemperatureAnalysis;
END;
GO

-- Use the GlobalTemperatureAnalysis database
USE GlobalTemperatureAnalysis;
GO

-- Create a table for the time series data if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeSeries]') AND type = N'U')
BEGIN
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
    );
END;

-- Import data from CSV file using BULK INSERT if the table is empty
IF NOT EXISTS (SELECT TOP 1 * FROM TimeSeries)
BEGIN
    BULK INSERT TimeSeries
    FROM 'C:\Users\Ken\temperature-analysis-project\data\raw\combined_time_series.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        TABLOCK
    );
END;

-- Create indexes to improve query performance if they don't already exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_TimeSeries_Temperature' AND object_id = OBJECT_ID(N'[dbo].[TimeSeries]'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_TimeSeries_Temperature ON TimeSeries(Temperature);
END;

PRINT 'Database setup and TimeSeries table creation completed.';
