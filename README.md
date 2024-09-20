# 🌡️ Global Temperature Analysis Project 🌍

A comprehensive data analysis pipeline for NOAA global temperature data, using R and SQL Server.

## 📋 Data Source

Uses NOAAGlobalTemp dataset, including:

- Global Historical Climate Network-Monthly (GHCNm) for land
- Extended Reconstructed Sea Surface Temperature (ERSST) for sea
- ICOADS and IABP for Arctic Ocean

## 📊 Dataset Details

1. **Time Series Data**: `combined_time_series.csv` (1850-present, anomalies vs. 1901-2000 average)
2. **Gridded Data**: `gridded_data.csv` (5° x 5° grid, anomalies vs. 1991-2020 base)

## 👥 Who Is This For?

- Climate researchers
- Data scientists working with environmental data
- Anyone interested in global temperature patterns

## ✨ Features

- Automated data download and processing of raw NOAA temperature data
- Robust SQL database for data storage and querying
- Comprehensive data cleaning and analysis
- Calculates statistics and identifies temperature trends
- Exports results for further use
- Enhanced error handling and detailed logging
- Improved data consistency checks
- Modular SQL script execution
- Automated database setup and table creation
- Progress tracking for data conversion and processing

## 🛠️ Requirements

- **R** (3.6.0+)
- **SQL Server** (2019+)
- **R packages**:

  ```
  curl, DBI, dplyr, httr, ncdf4, odbc, readr, xml2, progress, lubridate, tidyverse
  ```

  The script will automatically install and load these packages if they are not already available in your R environment.

## 🚀 How to Use

1. **Ensure** you have R and SQL Server installed on your system.
2. **Clone** the repository.
3. **Open** R or RStudio and set the working directory to the `R/` folder.
4. **Run** `runner.R`.
5. The script will automatically install any missing packages.
6. **Check** `data/processed/` for results and the SQL database for exploration data.

The script handles package installation, database setup, data download, and processing automatically.

## 📁 Project Structure

Before running, your project should look like this. After running, you'll find the empty folders filled with downloaded raw temperature data, processed CSVs, and more.

```
temperature-analysis-project/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── docs/
│   ├── database_schema.md
│   ├── data_dictionary.md
│   └── data_processing_pipeline.md
│
├── outputs/
│   ├── plots/
│   ├── tableau/
│   └── tables/
│
├── R/
│   ├── runner.R
│   └── utils.R
│
├── sql/
│   ├── drop_tables.sql
│   ├── explore_data.sql
│   ├── process_data.sql
│   ├── run_diagnostics.sql
│   └── setup_database.sql
│
├── .gitignore
└── README.md
```

## 🔍 Key Features

- Automated data download and conversion
- SQL database creation and management
- Enhanced error handling and logging in R scripts
- Improved SQL script execution with support for multiple statements
- Automated database and table creation
- Data consistency checks for `TimeSeries` and `GriddedData` tables
- Detailed diagnostic queries for data verification
- Progress bars for data conversion and processing tasks

## 🔜 Upcoming Features

- Advanced statistical analysis
- Machine learning integration
- Interactive visualization dashboard
- Geospatial analysis
- Correlation with other climate indicators

## 🤝 Contributions

Contributions, bug reports, and feature requests are welcome!

## 📜 Data Use and Citation

When using this data, please cite:

> NOAA National Centers for Environmental Information, Climate at a Glance: Global Time Series, published [Month] 2024, retrieved on [Date] from https://www.ncei.noaa.gov/access/monitoring/climate-at-a-glance/global/time-series

**Note**: Replace `[Month]` and `[Date]` with the actual month and date of retrieval.

## 📄 License

MIT License

---