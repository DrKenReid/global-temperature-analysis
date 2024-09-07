-- check_timeseries_table.sql
USE [$(SQL_DATABASE_NAME)]

-- Check row count
SELECT COUNT(*) AS TotalRows FROM TimeSeries;

-- Check first 10 rows
SELECT TOP 10 * FROM TimeSeries;

-- Check min and max years
SELECT MIN(Year) AS MinYear, MAX(Year) AS MaxYear FROM TimeSeries;

-- Check for any NULL values
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN Year IS NULL THEN 1 ELSE 0 END) AS NullYears,
    SUM(CASE WHEN Temperature IS NULL THEN 1 ELSE 0 END) AS NullTemperatures
FROM TimeSeries;
