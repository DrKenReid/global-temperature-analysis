USE GlobalTemperatureAnalysis;
GO

-- Print start time for logging
PRINT 'Starting TimeSeries analysis and cleaning at ' + CONVERT(VARCHAR, GETDATE(), 120);

-- Enable batch mode memory grant feedback for better performance
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_MEMORY_GRANT_FEEDBACK = ON;

-- 1. Check for missing values
PRINT 'Analyzing missing values...';
IF OBJECT_ID('tempdb..##MissingValuesAnalysis') IS NOT NULL DROP TABLE ##MissingValuesAnalysis;
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(Year) AS YearCount,
    COUNT(Temperature) AS TemperatureCount,
    COUNT(V3) AS V3Count,
    COUNT(V4) AS V4Count,
    COUNT(V5) AS V5Count,
    COUNT(V6) AS V6Count
INTO ##MissingValuesAnalysis
FROM TimeSeries WITH (NOLOCK);

-- Report on missing values
SELECT 
    TotalRows,
    TotalRows - YearCount AS MissingYears,
    TotalRows - TemperatureCount AS MissingTemperatures,
    TotalRows - V3Count AS MissingV3,
    TotalRows - V4Count AS MissingV4,
    TotalRows - V5Count AS MissingV5,
    TotalRows - V6Count AS MissingV6
FROM ##MissingValuesAnalysis;

-- 2. Get basic statistics for temperature
PRINT 'Calculating basic temperature statistics...';
IF OBJECT_ID('tempdb..##BasicStats') IS NOT NULL DROP TABLE ##BasicStats;
SELECT 
    AVG(Temperature) AS AvgTemperature,
    MIN(Temperature) AS MinTemperature,
    MAX(Temperature) AS MaxTemperature,
    STDEV(Temperature) AS StdDevTemperature
INTO ##BasicStats
FROM TimeSeries WITH (NOLOCK);

-- Report basic statistics
SELECT * FROM ##BasicStats;

-- 3. Check for outliers (temperatures more than 3 standard deviations from the mean)
PRINT 'Identifying temperature outliers...';
IF OBJECT_ID('tempdb..##Outliers') IS NOT NULL DROP TABLE ##Outliers;
;WITH Stats AS (
    SELECT AVG(Temperature) AS MeanTemp, STDEV(Temperature) AS StdDevTemp
    FROM TimeSeries WITH (NOLOCK)
)
SELECT TOP (1000) t.*
INTO ##Outliers
FROM TimeSeries t
CROSS JOIN Stats s
WHERE ABS(t.Temperature - s.MeanTemp) > 3 * s.StdDevTemp
ORDER BY ABS(t.Temperature - s.MeanTemp) DESC;

-- Report on outliers
DECLARE @OutlierCount INT;
SELECT @OutlierCount = COUNT(*) FROM ##Outliers;
PRINT 'Number of outliers detected: ' + CAST(@OutlierCount AS VARCHAR);

-- 4. Analyze temperature trends over time
PRINT 'Analyzing temperature trends...';
IF OBJECT_ID('tempdb..##TemperatureTrends') IS NOT NULL DROP TABLE ##TemperatureTrends;
SELECT 
    Year,
    AVG(Temperature) AS AvgTemperature
INTO ##TemperatureTrends
FROM TimeSeries WITH (NOLOCK)
GROUP BY Year
ORDER BY Year;

-- Report on temperature trends
SELECT 
    MIN(Year) AS EarliestYear,
    MAX(Year) AS LatestYear,
    AVG(AvgTemperature) AS OverallAvgTemperature
FROM ##TemperatureTrends;

-- Begin data cleaning
PRINT 'Starting data cleaning process...';

-- 1. Remove duplicates (if any)
PRINT 'Removing duplicates...';
WITH CTE AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Year ORDER BY (SELECT NULL)) AS RowNum
    FROM TimeSeries
)
DELETE FROM CTE 
OUTPUT DELETED.*
INTO ##DeletedDuplicates
WHERE RowNum > 1;

-- Report on removed duplicates
DECLARE @DuplicatesRemoved INT;
SELECT @DuplicatesRemoved = COUNT(*) FROM ##DeletedDuplicates;
PRINT 'Number of duplicates removed: ' + CAST(@DuplicatesRemoved AS VARCHAR);

-- 2. Handle missing values (replace -999 with NULL)
PRINT 'Handling missing values...';
DECLARE @MissingValuesReplaced INT;
UPDATE TimeSeries WITH (TABLOCK)
SET 
    V3 = NULLIF(V3, -999),
    V4 = NULLIF(V4, -999),
    V5 = NULLIF(V5, -999),
    V6 = NULLIF(V6, -999);
SET @MissingValuesReplaced = @@ROWCOUNT;
PRINT 'Number of rows with missing values replaced: ' + CAST(@MissingValuesReplaced AS VARCHAR);

-- 3. Create a clean version of the TimeSeries table
PRINT 'Creating clean version of TimeSeries...';
IF OBJECT_ID('dbo.CleanTimeSeries', 'U') IS NOT NULL DROP TABLE CleanTimeSeries;
SELECT *
INTO CleanTimeSeries
FROM TimeSeries
WHERE Year IS NOT NULL AND Temperature IS NOT NULL;

-- Report on clean data
DECLARE @OriginalRowCount INT, @CleanRowCount INT;
SELECT @OriginalRowCount = COUNT(*) FROM TimeSeries;
SELECT @CleanRowCount = COUNT(*) FROM CleanTimeSeries;
PRINT 'Original row count: ' + CAST(@OriginalRowCount AS VARCHAR);
PRINT 'Clean row count: ' + CAST(@CleanRowCount AS VARCHAR);
PRINT 'Rows removed in cleaning: ' + CAST(@OriginalRowCount - @CleanRowCount AS VARCHAR);

-- 4. Add century and decade columns for further analysis
PRINT 'Adding century and decade columns...';
ALTER TABLE CleanTimeSeries ADD 
    Century AS (FLOOR(Year / 100) + 1) PERSISTED,
    Decade AS (FLOOR(Year / 10) * 10) PERSISTED;

-- Create indexes on the new columns
CREATE NONCLUSTERED INDEX IX_CleanTimeSeries_Century ON CleanTimeSeries(Century);
CREATE NONCLUSTERED INDEX IX_CleanTimeSeries_Decade ON CleanTimeSeries(Decade);

-- Export results to CSV
PRINT 'Exporting results to CSV...';
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

DECLARE @cmd NVARCHAR(MAX);
DECLARE @outputPath NVARCHAR(255) = 'C:\Users\Ken\temperature-analysis-project\data\processed\';

SET @cmd = 'bcp "SELECT * FROM ##MissingValuesAnalysis" queryout "' + @outputPath + 'missing_values_analysis.csv" -c -t, -T -S .\KENSQL';
EXEC xp_cmdshell @cmd;

SET @cmd = 'bcp "SELECT * FROM ##BasicStats" queryout "' + @outputPath + 'basic_statistics.csv" -c -t, -T -S .\KENSQL';
EXEC xp_cmdshell @cmd;

SET @cmd = 'bcp "SELECT * FROM ##Outliers" queryout "' + @outputPath + 'outliers.csv" -c -t, -T -S .\KENSQL';
EXEC xp_cmdshell @cmd;

SET @cmd = 'bcp "SELECT * FROM ##TemperatureTrends" queryout "' + @outputPath + 'temperature_trends.csv" -c -t, -T -S .\KENSQL';
EXEC xp_cmdshell @cmd;

SET @cmd = 'bcp "SELECT * FROM CleanTimeSeries" queryout "' + @outputPath + 'clean_time_series.csv" -c -t, -T -S .\KENSQL';
EXEC xp_cmdshell @cmd;

-- Disable xp_cmdshell for security
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;

-- Final checks on cleaned data
PRINT 'Performing final checks on cleaned data...';
SELECT TOP 10 * FROM CleanTimeSeries ORDER BY Year;

-- Summary by Century
PRINT 'Generating summary by Century...';
SELECT 
    Century,
    COUNT(*) AS YearCount,
    AVG(Temperature) AS AvgTemperature,
    MIN(Temperature) AS MinTemperature,
    MAX(Temperature) AS MaxTemperature
FROM CleanTimeSeries
GROUP BY Century
ORDER BY Century;

-- Summary by Decade
PRINT 'Generating summary by Decade...';
SELECT 
    Decade,
    COUNT(*) AS YearCount,
    AVG(Temperature) AS AvgTemperature,
    MIN(Temperature) AS MinTemperature,
    MAX(Temperature) AS MaxTemperature
FROM CleanTimeSeries
GROUP BY Decade
ORDER BY Decade;

-- Print end time for logging
PRINT 'TimeSeries analysis and cleaning completed at ' + CONVERT(VARCHAR, GETDATE(), 120);