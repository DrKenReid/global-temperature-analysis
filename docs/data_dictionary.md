# Data Dictionary

## TimeSeries Table

| Column Name | Data Type | Description | Units |
|-------------|-----------|-------------|-------|
| Year        | INT       | The year of the temperature reading | Year (YYYY) |
| Temperature | FLOAT     | The global temperature anomaly for the year | Degrees Celsius, deviation from 1901-2000 average |
| V3          | FLOAT     | [Placeholder for future use] | N/A |
| V4          | FLOAT     | [Placeholder for future use] | N/A |
| V5          | FLOAT     | [Placeholder for future use] | N/A |
| V6          | FLOAT     | [Placeholder for future use] | N/A |
| V7          | VARCHAR(50) | [Placeholder for future use] | N/A |
| V8          | VARCHAR(50) | [Placeholder for future use] | N/A |
| V9          | VARCHAR(50) | [Placeholder for future use] | N/A |
| V10         | VARCHAR(50) | [Placeholder for future use] | N/A |

## GriddedData Table

| Column Name | Data Type | Description | Units |
|-------------|-----------|-------------|-------|
| ID          | INT       | Unique identifier for each data point (Auto-incrementing) | N/A |
| RowID       | INT       | Identifier for the time dimension (likely corresponding to years) | Year or time index |
| ColumnID    | INT       | Identifier for the spatial dimension (5° x 5° grid point) | Grid point index |
| Value       | FLOAT     | Temperature anomaly at the given location and time | Degrees Celsius, deviation from 1991-2020 average |

## ExplorationResults Table

| Column Name | Data Type | Description | Units |
|-------------|-----------|-------------|-------|
| ResultID    | INT       | Unique identifier for each exploration result (Auto-incrementing) | N/A |
| ExplorationName | NVARCHAR(100) | Name or description of the exploration analysis | N/A |
| ResultData  | NVARCHAR(MAX) | JSON-formatted data containing the exploration results | Varies |
| CreatedAt   | DATETIME  | Timestamp of when the result was created | Date and time |

Note: The GriddedData table uses a 5° x 5° grid for spatial representation. The RowID likely represents years, while ColumnID represents specific grid points on the Earth's surface.