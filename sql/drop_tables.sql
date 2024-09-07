-- drop_all_tables.sql

USE GlobalTemperatureAnalysis;
GO

DECLARE @sql NVARCHAR(MAX) = N'';

-- Generate DROP TABLE statements for all tables
SELECT @sql += N'
DROP TABLE IF EXISTS ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N';'
FROM sys.tables t
JOIN sys.schemas s ON t.[schema_id] = s.[schema_id]
WHERE t.type = 'U' -- User-defined tables only

-- Execute the generated SQL
EXEC sp_executesql @sql;


PRINT 'All tables have been dropped from the GlobalTemperatureAnalysis database.';
