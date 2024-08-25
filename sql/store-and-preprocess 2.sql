-- sql_operations.sql

USE GlobalTemperatureAnalysis;
GO

-- Create the final GriddedData table
CREATE TABLE GriddedData (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    RowID INT,
    ColumnID INT,
    Value FLOAT
);

-- Process the staged data
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
WHERE v.Value IS NOT NULL;

-- Clean up
DROP TABLE GriddedDataStaging;

-- Check the results
SELECT TOP 100 * FROM GriddedData;