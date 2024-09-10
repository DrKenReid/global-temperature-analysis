USE [$(SQL_DATABASE_NAME)]
SET NOCOUNT ON

PRINT 'Starting database setup and TimeSeries table creation...'

IF OBJECT_ID('dbo.TimeSeries', 'U') IS NULL
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

DECLARE @RowCount INT
EXEC dbo.GetTableRowCount 'TimeSeries', @RowCount OUTPUT
PRINT 'TimeSeries table row count: ' + CAST(@RowCount AS NVARCHAR(20))

IF @RowCount = 0
BEGIN
    PRINT 'TimeSeries table is empty. Data will be imported using PowerShell script.'
END
ELSE
BEGIN
    PRINT 'TimeSeries table already contains data.'
END
