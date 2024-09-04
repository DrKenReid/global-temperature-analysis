# 🌡️ Global Temperature Analysis Project 🌍

⚠️ **DISCLAIMER: WORK IN PROGRESS** ⚠️

**This project is currently under active development and is not yet complete. Features, documentation, and code are subject to change. Use with caution and expect frequent updates.**

---

This repository contains a comprehensive data analysis pipeline for global temperature data, implemented using R, SQL Server, and PowerShell. The project aims to process, clean, and analyze historical temperature data to uncover trends and insights about global climate patterns.

## 📋 Contents

1. **Data Download and Conversion**: R scripts to download raw temperature data and convert it to a usable format.
2. **SQL Database Operations**: SQL scripts for creating the database schema, importing data, and performing initial data cleaning.
3. **Data Processing Pipeline**: A combination of R, SQL, and PowerShell scripts that work together to process and analyze the temperature data.
4. **Data Cleaning and Analysis**: SQL scripts for detailed data cleaning, outlier detection, and basic statistical analysis.
5. **CSV Export**: Functionality to export processed data and analysis results to CSV files for further use or visualization in other tools.

## 👥 Who is this for?

This tool is ideal for:
- Climate researchers looking to analyze historical temperature trends
- Data scientists interested in working with large-scale environmental data
- Anyone curious about global temperature patterns and climate change indicators

## ✨ Features

- Downloads and processes raw temperature data from reliable sources
- Implements a robust SQL database for efficient data storage and querying
- Performs comprehensive data cleaning, including handling missing values and outlier detection
- Calculates basic statistics and identifies temperature trends over time
- Exports processed data and analysis results for further use
- Utilizes a combination of R, SQL, and PowerShell for a powerful and flexible data processing pipeline

## 🛠️ Requirements

- R (version 3.6.0 or higher)
- SQL Server (2019 or higher)
- PowerShell (version 5.1 or higher)
- R packages: here, DBI, odbc (install using `install.packages(c("here", "DBI", "odbc"))`)

## 🚀 Environment Setup

Before running the scripts, you need to set up the following environment variables:

- `SQL_SERVER_NAME`: The name of your SQL Server instance
- `SQL_DATABASE_NAME`: The name of the database (default: GlobalTemperatureAnalysis)
- `SQL_TABLE_NAME`: The name of the table for gridded data (default: GriddedDataStaging)
- `CSV_PATH`: The path to your gridded data CSV file

### Windows

Run the following commands in PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("SQL_SERVER_NAME", "your_server_name", "User")
[Environment]::SetEnvironmentVariable("SQL_DATABASE_NAME", "GlobalTemperatureAnalysis", "User")
[Environment]::SetEnvironmentVariable("SQL_TABLE_NAME", "GriddedDataStaging", "User")
[Environment]::SetEnvironmentVariable("CSV_PATH", "C:\path\to\your\gridded_data.csv", "User")
```

### macOS and Linux

Add the following lines to your `~/.bash_profile` (macOS) or `~/.bashrc` (Linux):

```bash
export SQL_SERVER_NAME="your_server_name"
export SQL_DATABASE_NAME="GlobalTemperatureAnalysis"
export SQL_TABLE_NAME="GriddedDataStaging"
export CSV_PATH="/path/to/your/gridded_data.csv"
```

Then, run `source ~/.bash_profile` (macOS) or `source ~/.bashrc` (Linux) to apply the changes.

## 🚀 How to Use

1. Ensure you have R, SQL Server, and PowerShell installed on your system.
2. Clone this repository to your local machine:
   ```
   git clone https://github.com/yourusername/global-temperature-analysis.git
   cd global-temperature-analysis
   ```
3. Set up the environment variables as described in the Environment Setup section.
4. Install required R packages:
   ```r
   install.packages(c("here", "DBI", "odbc"))
   ```
5. Run the `runner.R` script to start the data processing pipeline:
   ```r
   source("R/runner.R")
   ```
6. Check the `data/processed` directory for output CSV files containing analysis results.

## 🔧 Troubleshooting

If you encounter issues with the SqlServer PowerShell module, you may need to install it manually:

```powershell
Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber
```

## 🔜 Upcoming Features

- Advanced statistical analysis of temperature trends
- Integration with machine learning models for temperature prediction
- Interactive data visualization dashboard using Tableau
- Geospatial analysis of temperature patterns
- Correlation analysis with other climate indicators (e.g., CO2 levels, sea levels)

## 🤝 Contributions

Contributions, bug reports, and feature requests are welcome! Feel free to open an issue or submit a pull request.

## 📄 License

This project is licensed under the MIT License.

Analyze global temperatures and contribute to climate research! 🌡️🔬
