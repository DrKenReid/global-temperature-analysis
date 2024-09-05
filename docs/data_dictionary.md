# Data Dictionary

## TimeSeries Table

| Column Name | Data Type | Description | Units |
|-------------|-----------|-------------|-------|
| Year        | INT       | The year of the temperature reading | Year (YYYY) |
| Temperature | FLOAT     | The average global temperature for the year | Degrees Celsius |
| V3          | FLOAT     | [Description needed] | [Units needed] |
| V4          | FLOAT     | [Description needed] | [Units needed] |
| V5          | FLOAT     | [Description needed] | [Units needed] |
| V6          | FLOAT     | [Description needed] | [Units needed] |
| V7          | VARCHAR(50) | [Description needed] | N/A |
| V8          | VARCHAR(50) | [Description needed] | N/A |
| V9          | VARCHAR(50) | [Description needed] | N/A |
| V10         | VARCHAR(50) | [Description needed] | N/A |

## GriddedData Table

| Column Name | Data Type | Description | Units |
|-------------|-----------|-------------|-------|
| ID          | INT       | Unique identifier for each data point | N/A |
| RowID       | INT       | Identifier for the spatial row (e.g., latitude) | [Units needed] |
| ColumnID    | INT       | Identifier for the spatial column (e.g., longitude) | [Units needed] |
| Value       | FLOAT     | Temperature or temperature anomaly at the given location | Degrees Celsius or Deviation from baseline |

Note: Further details about V3-V10 in the TimeSeries table and the exact meaning of RowID and ColumnID in the GriddedData table are needed for a complete data dictionary.