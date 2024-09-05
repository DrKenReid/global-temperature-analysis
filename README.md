# 🌡️ Global Temperature Analysis Project 🌍

A comprehensive data analysis pipeline for NOAA global temperature data, using R, SQL Server, and PowerShell.

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
3. Data Processing Pipeline (R, SQL, PowerShell)
4. Data Cleaning and Analysis (SQL)
5. CSV Export

## 📁 Project Structure

```
temperature-analysis-project/
│
├── data/
│   ├── raw/
│   │   ├── combined_time_series.csv
│   │   └── gridded_data.csv
│   └── processed/
│
├── R/
│   ├── data_converter.R
│   ├── data_downloader.R
│   ├── runner.R
│   └── utils.R
│
├── sql/
│   ├── 1_setup_database_and_timeseries.sql
│   ├── 2_prepare_gridded_data_staging.sql
│   ├── 3_process_gridded_data.sql
│   ├── 4_data_exploration.sql
│   └── verify_data_processing.sql
│
└── ps1/
    ├── import-gridded-data.ps1
    └── utils.ps1
```

## 👥 Who is this for?

- Climate researchers
- Data scientists working with environmental data
- Anyone interested in global temperature patterns

## ✨ Features

- Processes raw NOAA temperature data
- Robust SQL database for data storage and querying
- Comprehensive data cleaning and analysis
- Calculates statistics and identifies temperature trends
- Exports results for further use

## 🛠️ Requirements

<table>
<tr>
<td>

- R (3.6.0+)
- SQL Server (2019+)
- PowerShell (5.1+)

</td>
<td>

- R packages: here, DBI, odbc, rvest, httr
- SqlServer PowerShell module

</td>
</tr>
</table>

### Installing SqlServer PowerShell Module

```powershell
Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber
```

## 🚀 How to Use

1. Install required software and modules
2. Clone the repository
3. Set working directory to `R/` folder
4. Run `runner.R`
5. Check `data/processed/` for results

## 🔜 Upcoming Features

- Advanced statistical analysis
- Machine learning integration
- Interactive visualization dashboard
- Geospatial analysis
- Correlation with other climate indicators

## 🤝 Contributions

Contributions, bug reports, and feature requests are welcome!

## 📜 Data Use and Citation

Thanks to NOAA for the data: https://www.ncei.noaa.gov/access/monitoring/climate-at-a-glance/global/time-series

## 📄 License

MIT License
