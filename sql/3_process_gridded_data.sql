USE [$(SQL_DATABASE_NAME)]
SET NOCOUNT ON

PRINT 'Starting GriddedData processing at ' + CONVERT(VARCHAR, GETDATE(), 120)

IF OBJECT_ID('dbo.GriddedDataStaging', 'U') IS NULL
BEGIN
    RAISERROR('GriddedDataStaging table does not exist.', 16, 1)
    RETURN
END

DECLARE @StagingRowCount INT
SELECT @StagingRowCount = COUNT(*) FROM GriddedDataStaging
IF @StagingRowCount = 0
BEGIN
    RAISERROR('GriddedDataStaging table is empty.', 16, 1)
    RETURN
END

PRINT 'GriddedDataStaging exists and contains ' + CAST(@StagingRowCount AS VARCHAR) + ' rows.'

IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.GriddedData
    PRINT 'Existing GriddedData table dropped.'
END

CREATE TABLE GriddedData (
    ID INT IDENTITY(1,1),
    RowID INT NOT NULL,
    ColumnID INT NOT NULL,
    Value FLOAT NOT NULL,
    INDEX CCI_GriddedData CLUSTERED COLUMNSTORE
)

PRINT 'GriddedData table created with clustered columnstore index.'

CREATE NONCLUSTERED INDEX IX_GriddedData_RowID_ColumnID ON GriddedData (RowID, ColumnID)

PRINT 'Nonclustered index created on GriddedData.'

PRINT 'Starting data processing from GriddedDataStaging to GriddedData...'

INSERT INTO GriddedData (RowID, ColumnID, Value)
SELECT
    s.RowID,
    v.ColumnID,
    v.Value
FROM GriddedDataStaging s
CROSS APPLY (
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ColumnID,
        TRY_CAST(value AS FLOAT) AS Value
    FROM STRING_SPLIT(s.RawData, ',')
) v
WHERE v.Value IS NOT NULL

DECLARE @GriddedDataRowCount INT
SELECT @GriddedDataRowCount = COUNT(*) FROM GriddedData
PRINT 'GriddedData now contains ' + CAST(@GriddedDataRowCount AS VARCHAR) + ' rows.'

IF @GriddedDataRowCount > 0
BEGIN
    TRUNCATE TABLE GriddedDataStaging
    PRINT 'GriddedDataStaging table truncated.'
END
ELSE
BEGIN
    PRINT 'Warning: GriddedData is empty. GriddedDataStaging was not truncated.'
END

PRINT 'Sample data from GriddedData:'
SELECT TOP 5 * FROM GriddedData

PRINT 'GriddedData statistics:'
SELECT 
    COUNT(*) AS TotalRows,
    MIN(Value) AS MinValue,
    MAX(Value) AS MaxValue,
    AVG(Value) AS AvgValue
FROM GriddedData

PRINT 'GriddedData processing completed at ' + CONVERT(VARCHAR, GETDATE(), 120)
