-- 3_process_gridded_data.sql
USE GlobalTemperatureAnalysis


SET NOCOUNT ON


-- Enable batch mode memory grant feedback for better performance
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_MEMORY_GRANT_FEEDBACK = ON


PRINT 'Starting GriddedData processing at ' + CONVERT(VARCHAR, GETDATE(), 120)


-- Check if GriddedDataStaging exists and has data
IF OBJECT_ID('dbo.GriddedDataStaging', 'U') IS NULL
BEGIN
    RAISERROR('GriddedDataStaging table does not exist.', 16, 1)
END
ELSE
BEGIN
    DECLARE @StagingRowCount INT
    SELECT @StagingRowCount = COUNT(*) FROM GriddedDataStaging
    IF @StagingRowCount = 0
    BEGIN
        RAISERROR('GriddedDataStaging table is empty.', 16, 1)
    END
    ELSE
    BEGIN
        PRINT 'GriddedDataStaging exists and contains ' + CAST(@StagingRowCount AS VARCHAR) + ' rows.'
    END
END


-- Create the final GriddedData table if it doesn't exist
IF OBJECT_ID('dbo.GriddedData', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.GriddedData
    PRINT 'Existing GriddedData table dropped.'
END


-- Create the table with a clustered columnstore index from the start
CREATE TABLE GriddedData (
    ID INT IDENTITY(1,1),
    RowID INT NOT NULL,
    ColumnID INT NOT NULL,
    Value FLOAT NOT NULL,
    INDEX CCI_GriddedData CLUSTERED COLUMNSTORE
)


PRINT 'GriddedData table created with clustered columnstore index.'


-- Create a nonclustered index for RowID and ColumnID
CREATE NONCLUSTERED INDEX IX_GriddedData_RowID_ColumnID ON GriddedData (RowID, ColumnID)


PRINT 'Nonclustered index created on GriddedData.'


-- Process the staged data
PRINT 'Starting data processing from GriddedDataStaging to GriddedData...'


DECLARE @BatchSize INT = 100000
DECLARE @RowsProcessed INT = 0
DECLARE @TotalRows INT

SELECT @TotalRows = COUNT(*) FROM GriddedDataStaging

WHILE @RowsProcessed < @TotalRows
BEGIN
    INSERT INTO GriddedData (RowID, ColumnID, Value)
    SELECT 
        s.RowID,
        v.ColumnID,
        v.Value
    FROM (
        SELECT TOP (@BatchSize) *
        FROM GriddedDataStaging
        WHERE RowID > @RowsProcessed
        ORDER BY RowID
    ) s
    CROSS APPLY (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ColumnID,
            TRY_CAST(value AS FLOAT) AS Value
        FROM STRING_SPLIT(s.RawData, ',')
    ) v
    WHERE v.Value IS NOT NULL

    SET @RowsProcessed = @RowsProcessed + @BatchSize
    PRINT 'Processed ' + CAST(@RowsProcessed AS VARCHAR) + ' rows out of ' + CAST(@TotalRows AS VARCHAR)
END


-- Verify data was inserted
DECLARE @GriddedDataRowCount INT
SELECT @GriddedDataRowCount = COUNT(*) FROM GriddedData
PRINT 'GriddedData now contains ' + CAST(@GriddedDataRowCount AS VARCHAR) + ' rows.'

-- Only drop GriddedDataStaging if data was successfully transferred
IF @GriddedDataRowCount > 0
BEGIN
    DROP TABLE GriddedDataStaging
    PRINT 'GriddedDataStaging table dropped.'
END
ELSE
BEGIN
    PRINT 'Warning: GriddedData is empty. GriddedDataStaging was not dropped.'
END

-- Check the results
PRINT 'Sample data from GriddedData:'
SELECT TOP 5 * FROM GriddedData

-- Get some statistics
PRINT 'GriddedData statistics:'
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT RowID) AS UniqueRows,
    COUNT(DISTINCT ColumnID) AS UniqueColumns,
    AVG(Value) AS AverageValue,
    MIN(Value) AS MinValue,
    MAX(Value) AS MaxValue
FROM GriddedData

PRINT 'GriddedData processing completed at ' + CONVERT(VARCHAR, GETDATE(), 120)
