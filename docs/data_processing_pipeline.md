# Data Processing Pipeline

## Overview

This document outlines the step-by-step process of our data processing pipeline for the Global Temperature Analysis project.

## Steps

1. **Environment Setup**
   - Script: `runner.R`
   - Purpose: Sets up the environment, loads required packages, and sets default environment variables.
   - Output: Prepared R environment for subsequent steps.

2. **Data Download**
   - Function: `download_data()` in `utils.R`
   - Purpose: Downloads raw data files from NOAA's website if they don't already exist.
   - Output: Raw .asc and .nc files in the `../data/raw/` directory.

3. **Data Conversion**
   - Function: `convert_data()` in `utils.R`
   - Purpose: Converts raw data files into CSV format.
   - Output: 
     - `combined_time_series.csv`: Processed time series data.
     - `gridded_data.csv`: Processed gridded data.

4. **Database Setup**
   - Function: `setup_database()` in `utils.R`
   - Script: `setup_database.sql`
   - Purpose: Creates the database schema and tables.
   - Output: Empty tables in the database (TimeSeries, GriddedData, ExplorationResults).

5. **Data Import**
   - Function: `import_data()` in `utils.R`
   - Purpose: Imports processed CSV data into the database tables.
   - Output: Populated TimeSeries and GriddedData tables.

6. **Data Processing**
   - Script: `process_data.sql`
   - Purpose: Processes the imported data, creating aggregated and derived tables.
   - Output: Populated ProcessedTimeSeries and ProcessedGriddedData tables.

7. **Data Exploration**
   - Script: `explore_data.sql`
   - Purpose: Performs data analysis and generates summary statistics.
   - Output: Various query results for temperature trends, hottest/coldest years, and temperature changes by latitude.

8. **Diagnostics**
   - Script: `run_diagnostics.sql`
   - Purpose: Runs diagnostic queries to verify data integrity and completeness.
   - Output: Diagnostic results for ProcessedGriddedData and ProcessedTimeSeries tables.

## Execution

The entire pipeline is orchestrated by the `runner.R` script, which calls each of these steps in sequence using the `run_pipeline_step()` function.

## Notes

- Ensure all environment variables are properly set before running the pipeline:
  - SQL_SERVER_NAME
  - SQL_DATABASE_NAME
  - VERBOSE
- The pipeline is designed to be idempotent, meaning it can be run multiple times without duplicating data.
- Always check the logs after running the pipeline to ensure successful processing.
- The pipeline includes error handling and logging at various stages to help diagnose issues.
- Progress bars are implemented for long-running tasks to provide visual feedback on the pipeline's progress.