# Database Schema

## Tables

### TimeSeries

```sql
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
```

### GriddedData

```sql
CREATE TABLE GriddedData (
    ID INT IDENTITY(1,1),
    RowID INT NOT NULL,
    ColumnID INT NOT NULL,
    Value FLOAT NOT NULL,
    INDEX CCI_GriddedData CLUSTERED COLUMNSTORE
)
```

### ExplorationResults

```sql
CREATE TABLE ExplorationResults (
    ResultID INT IDENTITY(1,1) PRIMARY KEY,
    ExplorationName NVARCHAR(100),
    ResultData NVARCHAR(MAX),
    CreatedAt DATETIME DEFAULT GETDATE()
)
```

## Indexes

- `PK_TimeSeries`: Clustered primary key on the `Year` column of the TimeSeries table.
- `CCI_GriddedData`: Clustered columnstore index on the GriddedData table for improved query performance.
- `IX_GriddedData_RowID_ColumnID`: Nonclustered index on RowID and ColumnID columns of the GriddedData table.

```sql
CREATE NONCLUSTERED INDEX IX_GriddedData_RowID_ColumnID ON GriddedData (RowID, ColumnID)
```

## Relationships

There is no explicit foreign key relationship between tables. However, there are implicit relationships:

- The `Year` in TimeSeries corresponds to `RowID` in GriddedData.
- The `ColumnID` in GriddedData represents spatial locations (5° x 5° grid points).

## Utility Functions

1. GetTableRowCount
```sql
CREATE PROCEDURE dbo.GetTableRowCount
    @TableName NVARCHAR(128),
    @RowCount INT OUTPUT
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'SELECT @RowCount = COUNT(*) FROM ' + QUOTENAME(@TableName);
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
END;
```

2. TableExists
```sql
CREATE FUNCTION dbo.TableExists
(
    @TableName NVARCHAR(128)
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;
    IF OBJECT_ID(@TableName, 'U') IS NOT NULL
        SET @Result = 1;
    RETURN @Result;
END;
```

## Notes

1. The TimeSeries table uses a traditional rowstore structure with a clustered primary key on the Year column. This is optimal for quick lookups by year and sequential scans.

2. The GriddedData table uses a clustered columnstore index, which is excellent for analytical queries and data compression, especially beneficial for large datasets.

3. The ExplorationResults table stores the results of various data exploration queries, allowing for easy retrieval and comparison of analysis results.

4. The additional nonclustered index on GriddedData (RowID, ColumnID) allows for quick lookups and joins on these columns when needed.

5. Consider adding appropriate indexes on frequently queried columns or combinations of columns to improve query performance.

6. Regularly update statistics on all tables to ensure optimal query performance:

   ```sql
   UPDATE STATISTICS TimeSeries WITH FULLSCAN
   UPDATE STATISTICS GriddedData WITH FULLSCAN
   UPDATE STATISTICS ExplorationResults WITH FULLSCAN
   ```

7. Monitor query performance and adjust indexing strategy as needed based on the most common query patterns.

8. The utility functions (GetTableRowCount and TableExists) provide helpful tools for managing and querying the database schema.