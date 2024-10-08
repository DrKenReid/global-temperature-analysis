
## **Updated `data_dictionary.md`**

# Data Dictionary

## **TimeSeries Table**

| Column Name  | Data Type | Description                                              | Units                                                     |
|--------------|-----------|----------------------------------------------------------|-----------------------------------------------------------|
| **Year**     | INT       | The year of the temperature reading                      | Year (YYYY)                                               |
| **Temperature** | FLOAT  | The global temperature anomaly for the year              | Degrees Celsius, deviation from 1901-2000 average         |

## **GriddedData Table**

| Column Name  | Data Type | Description                                              | Units                                                     |
|--------------|-----------|----------------------------------------------------------|-----------------------------------------------------------|
| **ID**       | INT       | Unique identifier for each data point (auto-incrementing) | N/A                                                       |
| **Longitude** | FLOAT    | Longitude of the grid point                              | Degrees                                                   |
| **Latitude** | FLOAT     | Latitude of the grid point                               | Degrees                                                   |
| **Time**     | FLOAT     | Time value representing the date                         | Days since 1850-01-01                                     |
| **Temperature** | FLOAT  | Temperature anomaly at the given location and time       | Degrees Celsius, deviation from 1991-2020 average         |

## **ProcessedTimeSeries Table**

| Column Name          | Data Type | Description                                          | Units                                             |
|----------------------|-----------|------------------------------------------------------|---------------------------------------------------|
| **Year**             | INT       | The year of the temperature reading                  | Year (YYYY)                                       |
| **AverageTemperature** | FLOAT   | The global average temperature anomaly for the year  | Degrees Celsius, deviation from 1901-2000 average |
| **TenYearMovingAverage** | FLOAT | Ten-year moving average of the temperature anomaly   | Degrees Celsius                                   |

## **ProcessedGriddedData Table**

| Column Name          | Data Type | Description                                            | Units                                         |
|----------------------|-----------|--------------------------------------------------------|-----------------------------------------------|
| **ID**               | INT       | Unique identifier for each data point (auto-incrementing) | N/A                                           |
| **Year**             | INT       | The year of the temperature reading                    | Year (YYYY)                                   |
| **Latitude**         | FLOAT     | Latitude of the grid point                             | Degrees                                       |
| **Longitude**        | FLOAT     | Longitude of the grid point                            | Degrees                                       |
| **AverageTemperature** | FLOAT   | Average temperature anomaly for the year at the location | Degrees Celsius                               |

## **ExplorationResults Table**

| Column Name    | Data Type      | Description                                           | Units |
|----------------|----------------|-------------------------------------------------------|-------|
| **ID**         | INT            | Unique identifier for each exploration result (auto-incrementing) | N/A   |
| **AnalysisName** | NVARCHAR(100) | Name or description of the analysis                   | N/A   |
| **Result**     | NVARCHAR(MAX)  | Concatenated string containing the analysis results   | N/A   |

**Note**: The `Result` column in the `ExplorationResults` table contains human-readable strings generated by concatenating various fields in the SQL scripts.

---
