# Data Processing Pipeline

## Overview

This document outlines the step-by-step process of our data processing pipeline for the Global Temperature Analysis project.

## Steps

1. **Data Download**
   - Script: `data_downloader.R`
   - Purpose: Downloads raw data files from NOAA's website.
   - Output: Raw .asc and .nc files in the `../data/raw/` directory.

2. **Data Conversion**
   - Script: `data_converter.R`
   - Purpose: Converts raw data files into CSV format.
   - Output: 
     - `combined_time_series.csv`: Processed time series data.
     - `gridded_data.csv`: Processed gridded data.

3. **Database Setup and TimeSeries Import**
   - Script: `1_setup_database_and_timeseries.sql`
   - Purpose: Creates the database schema and imports time series data.
   - Output: Populated TimeSeries table in the database.

4. **Prepare Gridded Data Staging**
   - Script: `2_prepare_gridded_data_staging.sql`
   - Purpose: Prepares a staging table for gridded data import.
   - Output: Empty GriddedDataStaging table in the database.

5. **Import Gridded Data**
   - Script: `import-gridded-data.ps1`
   - Purpose: Imports the large gridded dataset into the staging table.
   - Output: Populated GriddedDataStaging table.

6. **Process Gridded Data**
   - Script: `3_process_gridded_data.sql`
   - Purpose: Processes the staged gridded data and populates the final GriddedData table.
   - Output: Populated GriddedData table and dropped GriddedDataStaging table.

7. **Data Exploration**
   - Script: `4_data_exploration.sql`
   - Purpose: Performs initial data analysis and generates summary statistics.
   - Output: Various query results for data exploration.

8. **Verification**
   - Script: `verify_data_processing.sql`
   - Purpose: Verifies the integrity and completeness of the processed data.
   - Output: Verification report with table statistics and sample data.

## Execution

The entire pipeline is orchestrated by the `runner.R` script, which calls each of these steps in sequence.

## Notes

- Ensure all environment variables are properly set before running the pipeline.
- The pipeline is designed to be idempotent, meaning it can be run multiple times without duplicating data.
- Always check the logs and verification report after running the pipeline to ensure successful processing.