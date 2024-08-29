-- 2_prepare_gridded_data_staging.sql
USE GlobalTemperatureAnalysis;
GO

-- Drop and recreate GriddedDataStaging table
IF OBJECT_ID('dbo.GriddedDataStaging', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.GriddedDataStaging;
END;

CREATE TABLE GriddedDataStaging (
    RowID INT IDENTITY(1,1),
    RawData NVARCHAR(MAX)
);

-- Add a clustered columnstore index on GriddedDataStaging
CREATE CLUSTERED COLUMNSTORE INDEX CCI_GriddedDataStaging ON GriddedDataStaging;

PRINT 'GriddedDataStaging table prepared for data import.';
