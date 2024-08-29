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

## 🚀 How to Use

1. Ensure you have R, SQL Server, and PowerShell installed on your system.
2. Clone this repository to your local machine.
3. Run the `runner.R` script to start the data processing pipeline.
4. Check the `data/processed` directory for output CSV files containing analysis results.

## 🛠️ Requirements

- R (version 3.6.0 or higher)
- SQL Server (2019 or higher)
- PowerShell (version 5.1 or higher)
- R packages: here, DBI, odbc (install using `install.packages(c("here", "DBI", "odbc"))`)

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
