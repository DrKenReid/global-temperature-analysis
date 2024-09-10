# utils.R

library(DBI)
library(odbc)
library(readr)
library(ncdf4)
library(dplyr)

# Function to load required packages
load_required_packages <- function() {
  required_packages <- c("DBI", "odbc", "readr", "ncdf4", "dplyr")
  for(package in required_packages) {
    if(!require(package, character.only = TRUE)) {
      install.packages(package, dependencies = TRUE)
      library(package, character.only = TRUE)
    }
  }
}

# Function to set default environment variables
set_default_env_variables <- function() {
  if(Sys.getenv("SQL_SERVER_NAME") == "") Sys.setenv(SQL_SERVER_NAME = "(local)")
  if(Sys.getenv("SQL_DATABASE_NAME") == "") Sys.setenv(SQL_DATABASE_NAME = "GlobalTemperatureAnalysis")
  if(Sys.getenv("VERBOSE") == "") Sys.setenv(VERBOSE = "FALSE")
}

# Function to log messages
log_message <- function(message, level = "INFO") {
  cat(sprintf("[%s] %s: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), level, message))
}

# Function to safely read CSV files
safe_read_csv <- function(file) {
  tryCatch({
    if (grepl("\\.asc$", file)) {
      # For ASC files, use read.table with space as separator
      data <- read.table(file, header = FALSE, sep = " ", col.names = c("Year", "Temperature"))
      return(data)
    } else {
      # For other files, use read.csv as before
      read.csv(file, stringsAsFactors = FALSE)
    }
  }, error = function(e) {
    log_message(sprintf("Error reading file %s: %s", file, conditionMessage(e)), "ERROR")
    return(NULL)
  })
}

# Function to safely write CSV files
safe_write_csv <- function(data, file, verbose = FALSE) {
  tryCatch({
    write.csv(data, file, row.names = FALSE)
    if(verbose) log_message(sprintf("File written successfully: %s", file), "INFO")
  }, error = function(e) {
    log_message(sprintf("Error writing file %s: %s", file, conditionMessage(e)), "ERROR")
  })
}

# Function to count rows in a CSV file
count_csv_rows <- function(file) {
  tryCatch({
    length(readLines(file)) - 1  # Subtract 1 for the header
  }, error = function(e) {
    log_message(sprintf("Error counting rows in file %s: %s", file, conditionMessage(e)), "ERROR")
    return(0)
  })
}

# Function to connect to the database
db_connect <- function(verbose = FALSE) {
  tryCatch({
    con <- dbConnect(odbc::odbc(),
                     Driver = "ODBC Driver 17 for SQL Server",
                     Server = Sys.getenv("SQL_SERVER_NAME"),
                     Database = Sys.getenv("SQL_DATABASE_NAME"),
                     Trusted_Connection = "Yes")
    if(verbose) log_message("Connected to database successfully.", "INFO")
    return(con)
  }, error = function(e) {
    log_message(sprintf("Failed to connect to database: %s", conditionMessage(e)), "ERROR")
    stop(e)
  })
}

# Function to run pipeline steps
run_pipeline_step <- function(step_name, fun, ...) {
  log_message(sprintf("Starting %s", step_name), "INFO")
  tryCatch({
    result <- fun(...)
    log_message(sprintf("%s completed successfully.", step_name), "INFO")
    return(result)
  }, error = function(e) {
    log_message(sprintf("Error in %s: %s", step_name, conditionMessage(e)), "ERROR")
    return(NULL)
  })
}

# Function to download a single file
download_file <- function(url, destfile, max_attempts = 3) {
  for (attempt in 1:max_attempts) {
    tryCatch({
      temp_file <- tempfile()
      download.file(url, temp_file, mode = "wb", timeout = 600)
      file.rename(temp_file, destfile)
      return(TRUE)
    }, error = function(e) {
      log_message(sprintf("Attempt %d: Error downloading %s: %s", attempt, basename(url), conditionMessage(e)), "WARNING")
      if (attempt == max_attempts) {
        return(FALSE)
      }
      Sys.sleep(5)  # Wait 5 seconds before retrying
    })
  }
}

# Function to download data
download_data <- function() {
  base_url <- "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/"
  timeseries_url <- paste0(base_url, "timeseries/")
  gridded_url <- paste0(base_url, "gridded/")
  
  download_dir <- file.path("..", "data", "raw")
  dir.create(download_dir, showWarnings = FALSE, recursive = TRUE)
  
  all_files_downloaded <- TRUE
  
  # Download timeseries data
  timeseries_files <- c("aravg.ann.land_ocean.90S.90N.v6.0.0.202407.asc")
  for (file in timeseries_files) {
    if (download_file(paste0(timeseries_url, file), file.path(download_dir, file))) {
      log_message(sprintf("Successfully downloaded: %s", file.path(download_dir, file)), "INFO")
    } else {
      all_files_downloaded <- FALSE
    }
  }
  
  # Download gridded data
  gridded_files <- c("NOAAGlobalTemp_v6.0.0_gridded_s185001_e202407_c20240806T153047.nc")
  for (file in gridded_files) {
    if (download_file(paste0(gridded_url, file), file.path(download_dir, file))) {
      log_message(sprintf("Successfully downloaded: %s", file.path(download_dir, file)), "INFO")
    } else {
      all_files_downloaded <- FALSE
    }
  }
  
  if (all_files_downloaded) {
    log_message("All data files downloaded successfully.", "INFO")
    return(TRUE)
  } else {
    log_message("Some data files failed to download.", "ERROR")
    return(FALSE)
  }
}

# Function to convert data
convert_data <- function() {
  log_message("Starting data conversion...", "INFO")
  
  raw_dir <- file.path("..", "data", "raw")
  
  conversion_successful <- TRUE
  
  # Convert timeseries data
  timeseries_file <- file.path(raw_dir, "aravg.ann.land_ocean.90S.90N.v6.0.0.202407.asc")
  if (file.exists(timeseries_file)) {
    tryCatch({
      timeseries_data <- read.table(timeseries_file, header = FALSE, col.names = c("Year", "Temperature"))
      write.csv(timeseries_data, file.path(raw_dir, "combined_time_series.csv"), row.names = FALSE)
      log_message("Timeseries data converted successfully.", "INFO")
    }, error = function(e) {
      log_message(sprintf("Error converting timeseries data: %s", conditionMessage(e)), "ERROR")
      conversion_successful <- FALSE
    })
  } else {
    log_message("Timeseries file not found. Skipping conversion.", "WARNING")
    conversion_successful <- FALSE
  }
  
  # Convert gridded data
  gridded_file <- file.path(raw_dir, "NOAAGlobalTemp_v6.0.0_gridded_s185001_e202407_c20240806T153047.nc")
  if (file.exists(gridded_file)) {
    tryCatch({
      nc <- ncdf4::nc_open(gridded_file)
      lon <- ncdf4::ncvar_get(nc, "lon")
      lat <- ncdf4::ncvar_get(nc, "lat")
      temp <- ncdf4::ncvar_get(nc, "temperature")
      ncdf4::nc_close(nc)
      
      gridded_data <- expand.grid(Longitude = lon, Latitude = lat)
      gridded_data$Temperature <- as.vector(temp)
      write.csv(gridded_data, file.path(raw_dir, "gridded_data.csv"), row.names = FALSE)
      log_message("Gridded data converted successfully.", "INFO")
    }, error = function(e) {
      log_message(sprintf("Error converting gridded data: %s", conditionMessage(e)), "ERROR")
      conversion_successful <- FALSE
    })
  } else {
    log_message("Gridded data file not found. Skipping conversion.", "WARNING")
    conversion_successful <- FALSE
  }
  
  log_message("Data conversion completed.", "INFO")
  return(conversion_successful)
}

# Function to setup database
setup_database <- function(con) {
  execute_sql_file(con, "setup_database.sql")
}

# Function to import timeseries data
import_timeseries_data <- function(csv_path, con) {
  if (file.exists(csv_path)) {
    data <- read.csv(csv_path)
    dbWriteTable(con, "TimeSeries", data, append = TRUE, row.names = FALSE)
    return(nrow(data))
  } else {
    log_message(sprintf("File not found: %s", csv_path), "ERROR")
    return(0)
  }
}

# Function to import gridded data
import_gridded_data <- function(csv_path, con) {
  if (file.exists(csv_path)) {
    data <- read.csv(csv_path)
    dbWriteTable(con, "GriddedData", data, append = TRUE, row.names = FALSE)
    return(nrow(data))
  } else {
    log_message(sprintf("File not found: %s", csv_path), "ERROR")
    return(0)
  }
}

# Function to process data
process_data <- function(con) {
  execute_sql_file(con, "process_data.sql")
}

# Function to run diagnostics
run_diagnostics <- function(con) {
  execute_sql_file(con, "run_diagnostics.sql")
}

# Function to explore data
explore_data <- function(con) {
  execute_sql_file(con, "explore_data.sql")
}

# Function to execute SQL file
execute_sql_file <- function(con, filename) {
  sql_file <- file.path("sql", filename)
  if (file.exists(sql_file)) {
    sql_script <- readLines(sql_file, warn = FALSE)
    sql_script <- paste(sql_script, collapse = "\n")
    tryCatch({
      dbExecute(con, sql_script)
      log_message(sprintf("Executed SQL file: %s", filename), "INFO")
      return(TRUE)
    }, error = function(e) {
      log_message(sprintf("Error executing %s: %s", filename, conditionMessage(e)), "ERROR")
      return(FALSE)
    })
  } else {
    log_message(sprintf("%s file not found.", filename), "ERROR")
    return(FALSE)
  }
}