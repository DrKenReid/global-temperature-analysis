# utils.R

library(DBI)
library(dplyr)
library(httr)
library(ncdf4)
library(odbc)
library(readr)
library(curl)

convert_data <- function() {
  library(progress)
  library(ncdf4)
  
  log_message("Starting data conversion...")
  raw_dir <- file.path("..", "data", "raw")
  processed_dir <- file.path("..", "data", "processed")
  dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)
  
  timeseries_csv <- file.path(processed_dir, "combined_time_series.csv")
  gridded_csv <- file.path(processed_dir, "gridded_data.csv")
  
  # Check if CSVs already exist
  if (file.exists(timeseries_csv) && file.exists(gridded_csv)) {
    log_message("CSV files already exist. Skipping conversion.")
    return(TRUE)
  }
  
  # Process ASC file
  asc_file <- file.path(raw_dir, "aravg.ann.land_ocean.90S.90N.v6.0.0.202407.asc")
  if (file.exists(asc_file) && !file.exists(timeseries_csv)) {
    tryCatch({
      log_message("Converting timeseries data...")
      pb <- progress_bar$new(
        format = "[:bar] :percent eta: :eta",
        total = 100,
        clear = FALSE,
        width = 60
      )
      
      ts_data <- read.table(asc_file, header = FALSE, fill = TRUE, stringsAsFactors = FALSE)
      pb$tick(50)
      
      if (ncol(ts_data) >= 2) {
        ts_data <- ts_data[, 1:2]
        colnames(ts_data) <- c("Year", "Temperature")
        write.csv(ts_data, timeseries_csv, row.names = FALSE)
        pb$tick(50)
        log_message("Timeseries data converted successfully.")
      } else {
        log_message("ASC file does not have expected number of columns.", "ERROR")
      }
    }, error = function(e) {
      log_message(sprintf("Error converting ASC file: %s", conditionMessage(e)), "ERROR")
    })
  } else {
    log_message("ASC file not found or CSV already exists. Skipping timeseries conversion.")
  }
  
  # Process NC file
  nc_file <- file.path(raw_dir, "NOAAGlobalTemp_v6.0.0_gridded_s185001_e202407_c20240806T153047.nc")
  if (file.exists(nc_file) && file.size(nc_file) > 0 && !file.exists(gridded_csv)) {
    tryCatch({
      log_message("Converting gridded data...")
      pb <- progress_bar$new(
        format = "[:bar] :percent eta: :eta",
        total = 100,
        clear = FALSE,
        width = 60
      )
      
      nc <- nc_open(nc_file)
      pb$tick(20)
      
      var_name <- names(nc$var)[1]
      df <- expand.grid(Longitude = ncvar_get(nc, "lon"), Latitude = ncvar_get(nc, "lat"), Time = ncvar_get(nc, "time"))
      pb$tick(40)
      
      df$Temperature <- as.vector(ncvar_get(nc, var_name))
      pb$tick(20)
      
      nc_close(nc)
      write.csv(df, gridded_csv, row.names = FALSE)
      pb$tick(20)
      
      log_message("Gridded data converted successfully.")
    }, error = function(e) {
      log_message(sprintf("Error converting NC file: %s", conditionMessage(e)), "ERROR")
    })
  } else {
    log_message("NC file not found, empty, or CSV already exists. Skipping gridded data conversion.")
  }
  
  log_message("Data conversion completed.")
  TRUE
}

db_connect <- function(verbose = FALSE) {
  tryCatch({
    con <- dbConnect(odbc::odbc(),
                     Driver = "ODBC Driver 17 for SQL Server",
                     Server = Sys.getenv("SQL_SERVER_NAME"),
                     Database = Sys.getenv("SQL_DATABASE_NAME"),
                     Trusted_Connection = "Yes")
    if(verbose) log_message("Connected to database successfully.")
    con
  }, error = function(e) {
    log_message(sprintf("Failed to connect to database: %s", conditionMessage(e)), "ERROR")
    stop(e)
  })
}

debug_file_info <- function(file_path) {
  if (file.exists(file_path)) {
    info <- file.info(file_path)
    log_message(sprintf("File: %s, Size: %d bytes, Modified: %s", 
                        file_path, info$size, info$mtime))
    if (grepl("\\.csv$", file_path)) {
      tryCatch({
        data <- read.csv(file_path, nrows = 5)
        log_message(sprintf("CSV Preview (first 5 rows):\n%s", 
                            paste(capture.output(print(data)), collapse = "\n")))
      }, error = function(e) {
        log_message(sprintf("Error reading CSV: %s", conditionMessage(e)), "ERROR")
      })
    }
  } else {
    log_message(sprintf("File not found: %s", file_path), "ERROR")
  }
}

debug_env_vars <- function() {
  env_vars <- c("SQL_SERVER_NAME", "SQL_DATABASE_NAME", "VERBOSE")
  for (var in env_vars) {
    log_message(sprintf("%s: %s", var, Sys.getenv(var)))
  }
}

debug_db_connection <- function(con) {
  tryCatch({
    tables <- dbListTables(con)
    log_message(sprintf("Connected to database. Tables: %s", 
                        paste(tables, collapse = ", ")))
  }, error = function(e) {
    log_message(sprintf("Database connection error: %s", conditionMessage(e)), "ERROR")
  })
}

debug_download <- function(url, dest_file) {
  tryCatch({
    download.file(url, dest_file, mode = "wb")
    if (file.exists(dest_file) && file.size(dest_file) > 0) {
      log_message(sprintf("Successfully downloaded: %s (Size: %d bytes)", 
                          dest_file, file.size(dest_file)))
    } else {
      log_message(sprintf("Download failed or file is empty: %s", dest_file), "ERROR")
    }
  }, error = function(e) {
    log_message(sprintf("Error downloading %s: %s", url, conditionMessage(e)), "ERROR")
  })
}

download_data <- function() {
  base_url <- "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/"
  timeseries_url <- paste0(base_url, "timeseries/")
  gridded_url <- paste0(base_url, "gridded/")
  
  download_dir <- file.path("..", "data", "raw")
  dir.create(download_dir, showWarnings = FALSE, recursive = TRUE)
  
  csv_dir <- file.path("..", "data", "processed")
  dir.create(csv_dir, showWarnings = FALSE, recursive = TRUE)
  
  timeseries_csv <- file.path(csv_dir, "combined_time_series.csv")
  gridded_csv <- file.path(csv_dir, "gridded_data.csv")
  
  # Check if CSVs already exist
  if (file.exists(timeseries_csv) && file.exists(gridded_csv)) {
    return(TRUE)
  }
  
  download_file <- function(url, destfile, pb) {
    if (file.exists(destfile)) {
      log_message(sprintf("File %s already exists. Skipping download.", destfile))
      return(TRUE)
    }
    tryCatch({
      curl_download(url, destfile, mode = "wb")
      pb$tick()
      TRUE
    }, error = function(e) {
      log_message(sprintf("Error downloading %s: %s", url, conditionMessage(e)), "ERROR")
      pb$tick()
      FALSE
    })
  }
  
  # Get list of all ASC files
  asc_files <- httr::GET(timeseries_url) %>%
    httr::content("text") %>%
    xml2::read_html() %>%
    xml2::xml_find_all("//a[contains(@href, '.asc')]") %>%
    xml2::xml_attr("href")
  
  # Create progress bar for ASC files
  pb_asc <- progress_bar$new(
    format = "Downloading ASC files [:bar] :percent eta: :eta",
    total = length(asc_files),
    clear = FALSE,
    width = 60
  )
  
  asc_success <- sapply(asc_files, function(file) {
    download_file(paste0(timeseries_url, file), file.path(download_dir, file), pb_asc)
  })
  
  # Download NC file
  nc_file <- "NOAAGlobalTemp_v6.0.0_gridded_s185001_e202407_c20240806T153047.nc"
  
  # Create progress bar for NC file
  pb_nc <- progress_bar$new(
    format = "Downloading NC file [:bar] :percent eta: :eta",
    total = 1,
    clear = FALSE,
    width = 60
  )
  
  nc_success <- download_file(paste0(gridded_url, nc_file), file.path(download_dir, nc_file), pb_nc)
  
  log_message(sprintf("Downloaded %d/%d ASC files and %s NC file", sum(asc_success), length(asc_success), if(nc_success) "1/1" else "0/1"))
  
  all(asc_success) && nc_success
}

execute_sql_file <- function(con, filename) {
  if (file.exists(filename)) {
    tryCatch({
      sql_content <- paste(readLines(filename), collapse = "\n")
      sql_statements <- strsplit(sql_content, ";")[[1]]
      results <- list()
      for (statement in sql_statements) {
        if (trimws(statement) != "") {
          result <- dbGetQuery(con, statement)
          if (!is.null(result) && nrow(result) > 0) {
            results[[length(results) + 1]] <- result
          }
        }
      }
      log_message(sprintf("Executed SQL file: %s", filename))
      return(results)
    }, error = function(e) {
      log_message(sprintf("Error executing %s: %s", filename, conditionMessage(e)), "ERROR")
      return(NULL)
    })
  } else {
    log_message(sprintf("%s file not found.", filename), "ERROR")
    return(NULL)
  }
}

import_data <- function(csv_path, con, table_name) {
  csv_path <- file.path("..", "data", "processed", basename(csv_path))
  log_message(sprintf("Attempting to import data from: %s", csv_path))
  
  if (file.exists(csv_path)) {
    data <- read.csv(csv_path)
    log_message(sprintf("Successfully read %d rows from %s", nrow(data), csv_path))
    
    # Delete existing data
    delete_query <- sprintf("DELETE FROM %s", table_name)
    log_message(sprintf("Executing query: %s", delete_query))
    dbExecute(con, delete_query)
    
    # Import new data
    log_message(sprintf("Importing %d rows into %s table", nrow(data), table_name))
    dbWriteTable(con, table_name, data, append = TRUE, row.names = FALSE)
    
    imported_rows <- dbGetQuery(con, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    log_message(sprintf("Successfully imported %d rows into %s table", imported_rows, table_name))
    
    return(imported_rows)
  } else {
    log_message(sprintf("File not found: %s", csv_path), "ERROR")
    return(0)
  }
}

load_required_packages <- function() {
  required_packages <- c("curl", "DBI", "dplyr", "httr", "ncdf4", "odbc", "readr", "xml2", "progress", "lubridate", "tidyverse")
  sapply(required_packages, function(package) {
    if(!require(package, character.only = TRUE)) {
      install.packages(package, dependencies = TRUE)
      library(package, character.only = TRUE)
    }
  })
}

log_message <- function(message, level = "INFO") {
  log_entry <- sprintf("[%s] %s: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), level, message)
  cat(log_entry)
  write(log_entry, file = "pipeline.log", append = TRUE)
}

run_pipeline_step <- function(step_name, fun, ...) {
  log_message(sprintf("Starting %s", step_name))
  result <- tryCatch(fun(...), error = function(e) {
    log_message(sprintf("Error in %s: %s", step_name, conditionMessage(e)), "ERROR")
    NULL
  })
  log_message(sprintf("%s %s.", step_name, if(is.null(result)) "failed" else "completed successfully"))
  result
}

set_default_env_variables <- function() {
  if(Sys.getenv("SQL_SERVER_NAME") == "") Sys.setenv(SQL_SERVER_NAME = "(local)")
  if(Sys.getenv("SQL_DATABASE_NAME") == "") Sys.setenv(SQL_DATABASE_NAME = "GlobalTemperatureAnalysis")
  if(Sys.getenv("VERBOSE") == "") Sys.setenv(VERBOSE = "FALSE")
}

setup_database <- function(con) {
  sql_file <- file.path("..", "sql", "setup_database.sql")
  if (file.exists(sql_file)) {
    sql_script <- gsub("\\$\\(SQL_DATABASE_NAME\\)", Sys.getenv("SQL_DATABASE_NAME"), 
                       paste(readLines(sql_file), collapse = "\n"))
    tryCatch({
      dbExecute(con, sql_script)
      log_message("Database setup completed successfully.")
      TRUE
    }, error = function(e) {
      log_message(sprintf("Error executing SQL script: %s", conditionMessage(e)), "ERROR")
      FALSE
    })
  } else {
    log_message(sprintf("SQL file not found: %s", sql_file), "ERROR")
    FALSE
  }
}