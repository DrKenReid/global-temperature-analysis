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

## Indexes

- `PK_TimeSeries`: Clustered primary key on the `Year` column of the TimeSeries table.
- `CCI_GriddedData`: Clustered columnstore index on the GriddedData table for improved query performance.
- `IX_GriddedData_RowID_ColumnID`: Nonclustered index on RowID and ColumnID columns of the GriddedData table.

```sql
CREATE NONCLUSTERED INDEX IX_GriddedData_RowID_ColumnID ON GriddedData (RowID, ColumnID)
```

## Relationships

There is no explicit foreign key relationship between TimeSeries and GriddedData tables. However, there may be an implicit relationship where:

- The `Year` in TimeSeries could correspond to `RowID` in GriddedData (if RowID represents years).
- The `ColumnID` in GriddedData likely represents spatial locations.

## Notes

1. The TimeSeries table uses a traditional rowstore structure with a clustered primary key on the Year column. This is optimal for quick lookups by year and sequential scans.

2. The GriddedData table uses a clustered columnstore index, which is excellent for analytical queries and data compression, especially beneficial for large datasets.

3. The additional nonclustered index on GriddedData (RowID, ColumnID) allows for quick lookups and joins on these columns when needed.

4. Consider adding appropriate indexes on frequently queried columns or combinations of columns to improve query performance.

5. Regularly update statistics on both tables to ensure optimal query performance:

   ```sql
   UPDATE STATISTICS TimeSeries WITH FULLSCAN
   UPDATE STATISTICS GriddedData WITH FULLSCAN
   ```

6. Monitor query performance and adjust indexing strategy as needed based on the most common query patterns.