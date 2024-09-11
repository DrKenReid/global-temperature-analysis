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

## 🛠️ Project Components

1. Data Download and Conversion (R)
2. SQL Database Operations
3. Data Processing Pipeline (R, SQL)
4. Data Cleaning and Analysis (SQL)
5. CSV Export
6. Enhanced Error Handling and Logging

## 📁 Project Structure

```
temperature-analysis-project/
│
├── data/
│   ├── raw/
│   │   ├── aravg.ann.land_ocean.90S.90N.v6.0.0.202407.asc
│   │   └── NOAAGlobalTemp_v6.0.0_gridded_s185001_e202407_c20240806T153047.nc
│   └── processed/
│       ├── combined_time_series.csv
│       └── gridded_data.csv
│
├── R/
│   ├── runner.R
│   └── utils.R
│
└── sql/
    ├── setup_database.sql
    ├── process_data.sql
    ├── run_diagnostics.sql
    └── explore_data.sql
```

## 👥 Who is this for?

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

## 🛠️ Requirements

- R (3.6.0+)
- SQL Server (2019+)

R packages: DBI, dplyr, httr, ncdf4, odbc, readr, curl

## 🚀 How to Use

1. Ensure you have R and SQL Server installed on your system
2. Clone the repository
3. Open R or RStudio and set the working directory to the `R/` folder
4. Run `runner.R`
5. Check `data/processed/` for results and the SQL database for exploration data

The script will automatically handle database setup, data download, and processing.

## 🔍 Key Features

- Automated data download and conversion
- SQL database creation and management
- Enhanced error handling and logging in R scripts
- Improved SQL script execution with support for multiple statements
- Automated database and table creation
- Data consistency checks for TimeSeries and GriddedData tables
- Detailed diagnostic queries for data verification

## 🔜 Upcoming Features

- Advanced statistical analysis
- Machine learning integration
- Interactive visualization dashboard
- Geospatial analysis
- Correlation with other climate indicators

## 🤝 Contributions

Contributions, bug reports, and feature requests are welcome!

## 📜 Data Use and Citation

When using this data, cite: NOAA National Centers for Environmental Information, Climate at a Glance: Global Time Series, published [Month] 2024, retrieved on [Date] from https://www.ncei.noaa.gov/access/monitoring/climate-at-a-glance/global/time-series

## 📄 License

MIT License
