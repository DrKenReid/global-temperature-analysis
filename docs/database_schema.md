# Database Schema

## Tables

### TimeSeries

```sql
CREATE TABLE [dbo].[TimeSeries](
    [Year] INT NOT NULL PRIMARY KEY,
    [Temperature] FLOAT NOT NULL
)
```

### GriddedData

```sql
CREATE TABLE [dbo].[GriddedData] (
    [ID] INT IDENTITY(1,1) PRIMARY KEY,
    [Longitude] FLOAT NOT NULL,
    [Latitude] FLOAT NOT NULL,
    [Time] FLOAT NOT NULL,
    [Temperature] FLOAT NOT NULL
)
```

### ProcessedTimeSeries

```sql
CREATE TABLE [dbo].[ProcessedTimeSeries] (
    [Year] INT PRIMARY KEY,
    [AverageTemperature] FLOAT,
    [TenYearMovingAverage] FLOAT
)
```

### ProcessedGriddedData

```sql
CREATE TABLE [dbo].[ProcessedGriddedData] (
    [ID] INT IDENTITY(1,1) PRIMARY KEY,
    [Year] INT,
    [Latitude] FLOAT,
    [Longitude] FLOAT,
    [AverageTemperature] FLOAT
)
```

### ExplorationResults

```sql
CREATE TABLE [dbo].[ExplorationResults](
    [ID] INT IDENTITY(1,1) PRIMARY KEY,
    [AnalysisName] NVARCHAR(100) NOT NULL,
    [Result] NVARCHAR(MAX) NOT NULL
)
```

## Indexes

- `PK_TimeSeries`: Clustered primary key on the `Year` column of the TimeSeries table.
- `PK_GriddedData`: Clustered primary key on the `ID` column of the GriddedData table.
- `PK_ProcessedTimeSeries`: Clustered primary key on the `Year` column of the ProcessedTimeSeries table.
- `PK_ProcessedGriddedData`: Clustered primary key on the `ID` column of the ProcessedGriddedData table.
- `PK_ExplorationResults`: Clustered primary key on the `ID` column of the ExplorationResults table.

## Relationships

There are no explicit foreign key relationships between tables. However, there are implicit relationships:

- The `Year` in TimeSeries and ProcessedTimeSeries corresponds to the derived `Year` in ProcessedGriddedData.
- The `Time` in GriddedData represents days since January 1, 1850, which can be converted to years for comparison with other tables.

## Notes

1. The TimeSeries and ProcessedTimeSeries tables use the Year as the primary key for quick lookups and to ensure data integrity (one record per year).

2. The GriddedData table stores raw data with high temporal resolution (using the Time column), while ProcessedGriddedData aggregates this data annually.

3. The ExplorationResults table stores the results of various data exploration queries, allowing for easy retrieval and comparison of analysis results.

4. Consider adding appropriate indexes on frequently queried columns or combinations of columns to improve query performance, especially for the GriddedData and ProcessedGriddedData tables.

5. Regularly update statistics on all tables to ensure optimal query performance:

   ```sql
   UPDATE STATISTICS TimeSeries WITH FULLSCAN
   UPDATE STATISTICS GriddedData WITH FULLSCAN
   UPDATE STATISTICS ProcessedTimeSeries WITH FULLSCAN
   UPDATE STATISTICS ProcessedGriddedData WITH FULLSCAN
   UPDATE STATISTICS ExplorationResults WITH FULLSCAN
   ```

6. Monitor query performance and adjust indexing strategy as needed based on the most common query patterns.

7. The schema allows for efficient storage of both raw and processed data, facilitating both detailed and aggregated analyses of global temperature trends.