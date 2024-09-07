# utils.R

# Load required packages
load_required_packages <- function() {
  required_packages <- c("here", "DBI", "odbc", "R.utils", "readr", "dplyr", "lubridate", "jsonlite")
  for(package in required_packages) {
    if(!require(package, character.only = TRUE)) {
      install.packages(package, dependencies = TRUE)
      library(package, character.only = TRUE)
    }
  }
}

# Set default environment variables
set_default_env_variables <- function() {
  if(Sys.getenv("SQL_SERVER_NAME") == "") Sys.setenv(SQL_SERVER_NAME = "(local)")
  if(Sys.getenv("SQL_DATABASE_NAME") == "") Sys.setenv(SQL_DATABASE_NAME = "GlobalTemperatureAnalysis")
  if(Sys.getenv("SQL_TABLE_NAME") == "") Sys.setenv(SQL_TABLE_NAME = "GriddedDataStaging")
  if(Sys.getenv("VERBOSE") == "") Sys.setenv(VERBOSE = "FALSE")
}

# Verbose logging function
verbose_log <- function(message, verbose = FALSE) {
  if (verbose) {
    cat(paste0(Sys.time(), " - ", message, "\n"))
  }
}

# Function to check if all required environment variables are set
check_env_variables <- function(required_vars = c("SQL_SERVER_NAME", "SQL_DATABASE_NAME", "SQL_TABLE_NAME")) {
  missing_vars <- required_vars[sapply(required_vars, function(x) Sys.getenv(x) == "")]
  
  if (length(missing_vars) > 0) {
    stop(paste("Error: The following required environment variables are not set:", 
               paste(missing_vars, collapse = ", ")))
  }
}

# Function to establish a database connection
db_connect <- function(server = Sys.getenv("SQL_SERVER_NAME"), 
                       database = Sys.getenv("SQL_DATABASE_NAME"), 
                       verbose = FALSE) {
  verbose_log("Connecting to database...", verbose)
  tryCatch({
    con <- dbConnect(odbc::odbc(), 
                     Driver = "ODBC Driver 17 for SQL Server", 
                     Server = server,
                     Database = database,
                     Trusted_Connection = "Yes")
    verbose_log("Database connection established.", verbose)
    return(con)
  }, error = function(e) {
    stop(paste("Error connecting to database:", conditionMessage(e)))
  })
}

# Function to ensure SQL Server is installed and running
ensure_sql_server <- function() {
  tryCatch({
    con <- DBI::dbConnect(odbc::odbc(), 
                          Driver = "SQL Server", 
                          Server = Sys.getenv("SQL_SERVER_NAME"),
                          Trusted_Connection = "Yes")
    DBI::dbDisconnect(con)
  }, error = function(e) {
    stop("SQL Server is not installed or not running. Please install and start SQL Server.")
  })
}

# Function to install PowerShell module
install_powershell_module <- function() {
  system("powershell -Command \"& {Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser}\"")
}

# Function to safely execute SQL queries
safe_dbExecute <- function(con, query, verbose = FALSE) {
  verbose_log(paste("Executing query:", query), verbose)
  tryCatch({
    result <- dbExecute(con, query)
    verbose_log(paste("Query executed successfully. Rows affected:", result), verbose)
    return(result)
  }, error = function(e) {
    warning(paste("Error executing query:", conditionMessage(e)))
    return(NULL)
  })
}

# Function to safely fetch query results
safe_dbGetQuery <- function(con, query, verbose = FALSE) {
  verbose_log(paste("Fetching query results:", query), verbose)
  tryCatch({
    result <- dbGetQuery(con, query)
    verbose_log(paste("Query results fetched. Rows:", nrow(result)), verbose)
    return(result)
  }, error = function(e) {
    warning(paste("Error fetching query results:", conditionMessage(e)))
    return(NULL)
  })
}

# Function to check if a table exists in the database
table_exists <- function(con, table_name, verbose = FALSE) {
  verbose_log(paste("Checking if table exists:", table_name), verbose)
  query <- paste0("SELECT OBJECT_ID('", table_name, "') AS object_id")
  result <- safe_dbGetQuery(con, query, verbose)
  exists <- !is.null(result) && !is.na(result$object_id)
  verbose_log(paste("Table", table_name, if(exists) "exists" else "does not exist"), verbose)
  return(exists)
}

# Function to read CSV files safely
safe_read_csv <- function(file_path, verbose = FALSE) {
  verbose_log(paste("Reading CSV file:", file_path), verbose)
  tryCatch({
    data <- read_csv(file_path, show_col_types = FALSE)
    verbose_log(paste("CSV file read successfully. Rows:", nrow(data)), verbose)
    return(data)
  }, error = function(e) {
    warning(paste("Error reading CSV file:", conditionMessage(e)))
    return(NULL)
  })
}

# Function to write CSV files safely
safe_write_csv <- function(data, file_path, verbose = FALSE) {
  verbose_log(paste("Writing CSV file:", file_path), verbose)
  tryCatch({
    write_csv(data, file_path)
    verbose_log("CSV file written successfully.", verbose)
    return(TRUE)
  }, error = function(e) {
    warning(paste("Error writing CSV file:", conditionMessage(e)))
    return(FALSE)
  })
}

# Function to run R scripts safely
run_r_script <- function(script_name, verbose = FALSE) {
  script_path <- file.path(here::here(), script_name)
  cat(paste("  Running", script_name, "...\n"))
  if (file.exists(script_path)) {
    tryCatch({
      result <- source(script_path, local = new.env())$value
      cat(paste("  ", script_name, "completed.\n"))
      return(result)
    }, error = function(e) {
      cat(paste("  Error in", script_name, ":", conditionMessage(e), "\n"))
      return(NULL)
    })
  } else {
    cat(paste("  R script not found:", script_path, "\n"))
    return(NULL)
  }
}

# Function to run SQL scripts safely
run_sql_script <- function(script_name, con, verbose = FALSE, csv_path = NULL) {
  script_path <- file.path(here::here(), "..", "sql", script_name)
  log_message(paste("Running", script_name, "..."), "INFO")
  if (file.exists(script_path)) {
    tryCatch({
      sql_script <- readLines(script_path)
      sql_script <- paste(sql_script, collapse = "\n")
      
      # Replace placeholders with actual values
      sql_script <- gsub("\\$\\(SQL_DATABASE_NAME\\)", Sys.getenv("SQL_DATABASE_NAME"), sql_script)
      sql_script <- gsub("\\$\\(SQL_TABLE_NAME\\)", Sys.getenv("SQL_TABLE_NAME"), sql_script)
      sql_script <- gsub("\\$\\(VERBOSE\\)", as.character(as.integer(verbose)), sql_script)
      
      # Replace CSV_PATH if provided
      if (!is.null(csv_path)) {
        sql_script <- gsub("\\$\\(CSV_PATH\\)", csv_path, sql_script)
      }
      
      # Split the script into individual statements
      statements <- strsplit(sql_script, ";")[[1]]
      
      results <- list()
      for (i in seq_along(statements)) {
        stmt <- trimws(statements[i])
        if (stmt != "") {
          log_message(paste("Executing statement", i, "of", length(statements)), "INFO")
          result <- tryCatch({
            if (grepl("^SELECT|^PRINT|^DECLARE|^SET", stmt, ignore.case = TRUE)) {
              safe_dbGetQuery(con, stmt, verbose)
            } else {
              safe_dbExecute(con, stmt, verbose)
              NULL  # Return NULL for non-SELECT statements
            }
          }, error = function(e) {
            log_message(paste("Error in statement", i, ":", conditionMessage(e)), "ERROR")
            log_message("Problematic SQL:", "ERROR")
            log_message(stmt, "ERROR")
            NULL
          })
          if (!is.null(result) && nrow(result) > 0) {
            results[[length(results) + 1]] <- result
          }
        }
      }
      log_message(paste(script_name, "completed."), "INFO")
      return(results)
    }, error = function(e) {
      log_message(paste("Error in", script_name, ":", conditionMessage(e)), "ERROR")
      stop(paste("Error in", script_name, ":", conditionMessage(e)))
    })
  } else {
    log_message(paste("SQL script not found:", script_path), "ERROR")
    stop(paste("SQL script not found:", script_path))
  }
}

# Function to print SQL results
print_sql_results <- function(results) {
  if (length(results) == 0) {
    cat("No results to display.\n")
  } else {
    for (i in seq_along(results)) {
      cat(paste("Result set", i, ":\n"))
      if (is.data.frame(results[[i]])) {
        if (nrow(results[[i]]) > 5) {
          print(head(results[[i]], 5))
          cat(paste("... and", nrow(results[[i]]) - 5, "more rows\n"))
        } else {
          print(results[[i]])
        }
      } else {
        cat(paste0(results[[i]], "\n"))
      }
      cat("\n")
    }
  }
}

# Function to count rows in a CSV file
count_csv_rows <- function(file_path) {
  con <- file(file_path, "r")
  row_count <- 0
  while (length(readLines(con, n = 1)) > 0) {
    row_count <- row_count + 1
  }
  close(con)
  return(row_count)
}

# Function to check file existence
check_file_existence <- function(file_path, file_description) {
  exists <- file.exists(file_path)
  cat(paste("  ", file_description, "file exists:", exists, "\n"))
  return(exists)
}

# Function to handle data conversion results
handle_conversion_results <- function(conversion_result) {
  if (is.null(conversion_result) || (is.list(conversion_result) && length(conversion_result) == 0)) {
    cat("  Warning: No data conversion results reported. Verify if conversion process completed successfully.\n")
    cat("  Checking if output files exist:\n")
    timeseries_file <- file.path("..", "data", "raw", "combined_time_series.csv")
    gridded_file <- file.path("..", "data", "raw", "gridded_data.csv")
    check_file_existence(timeseries_file, "TimeSeries")
    check_file_existence(gridded_file, "GriddedData")
  } else {
    if (!is.null(conversion_result$asc_result)) {
      cat(paste("  Processed", conversion_result$asc_result$file_count, "ASC files.\n"))
      cat(paste("  TimeSeries output file contains", conversion_result$asc_result$row_count, "rows.\n"))
    }
    if (!is.null(conversion_result$nc_result)) {
      cat(paste("  Processed", conversion_result$nc_result$file_count, "NC files.\n"))
      cat(paste("  GriddedData output file contains", conversion_result$nc_result$row_count, "rows.\n"))
    }
  }
}

# Function to handle import results
handle_import_results <- function(import_result) {
  if (!is.null(import_result)) {
    cat(paste("  Imported", import_result$GriddedDataStaging, "rows into GriddedDataStaging.\n"))
    cat(paste("  TimeSeries table contains", import_result$TimeSeries, "rows.\n"))
  } else {
    cat("  Warning: No import results reported.\n")
  }
}

# Function to verify data processing results
verify_data_processing <- function(results, verbose) {
  print_sql_results(results)
  if (length(results) == 0 || all(sapply(results, function(x) nrow(x) == 0))) {
    cat("  Warning: No data found in the database tables. Running database diagnosis.\n")
    diagnose_database_tables(verbose)
  } else {
    cat("  Data verification completed. Check the results above for details.\n")
  }
}

# Logging utility function
log_message <- function(message, level = "INFO", file = "pipeline.log") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] %s: %s\n", timestamp, level, message)
  cat(log_entry)
  write(log_entry, file = file, append = TRUE)
}

# Function to check data consistency
check_data_consistency <- function(con, table_name, expected_columns, expected_rows = NULL) {
  log_message(sprintf("Checking data consistency for table: %s", table_name), "INFO")
  
  # Check if table exists
  if (!table_exists(con, table_name)) {
    log_message(sprintf("Table %s does not exist", table_name), "ERROR")
    return(FALSE)
  }
  
  # Check column names
  query <- sprintf("SELECT TOP 1 * FROM %s", table_name)
  result <- safe_dbGetQuery(con, query)
  if (is.null(result)) {
    log_message(sprintf("Failed to fetch data from %s", table_name), "ERROR")
    return(FALSE)
  }
  actual_columns <- names(result)
  missing_columns <- setdiff(expected_columns, actual_columns)
  if (length(missing_columns) > 0) {
    log_message(sprintf("Missing columns in %s: %s", table_name, paste(missing_columns, collapse = ", ")), "ERROR")
    return(FALSE)
  }
  
  # Check row count if expected_rows is provided
  if (!is.null(expected_rows)) {
    row_count <- safe_dbGetQuery(con, sprintf("SELECT COUNT(*) AS count FROM %s", table_name))$count
    if (row_count != expected_rows) {
      log_message(sprintf("Unexpected row count in %s. Expected: %d, Actual: %d", table_name, expected_rows, row_count), "ERROR")
      return(FALSE)
    }
  }
  
  log_message(sprintf("Data consistency check passed for %s", table_name), "INFO")
  return(TRUE)
}

# Function to run a step in the pipeline
run_pipeline_step <- function(step_name, fun, ...) {
  cat(paste(step_name, ":\n"))
  tryCatch({
    result <- fun(...)
    cat(paste("  ", step_name, "completed successfully.\n\n"))
    return(result)
  }, error = function(e) {
    cat(paste("  Error in", step_name, ":", conditionMessage(e), "\n"))
    cat("  Stack trace:\n")
    print(sys.calls())
    cat("\n")
    return(NULL)
  }, warning = function(w) {
    cat(paste("  Warning in", step_name, ":", conditionMessage(w), "\n\n"))
  })
}

# Function to run PowerShell scripts safely
run_powershell_script <- function(script_name, verbose = FALSE) {
  project_root <- dirname(here::here())
  script_path <- file.path(project_root, "ps1", script_name)
  if (!verbose) {
    cat(paste("  Running", script_name, "...\n"))
  }
  verbose_log(paste("Running PowerShell script:", script_path), verbose)
  
  if (file.exists(script_path)) {
    original_wd <- getwd()
    setwd(project_root)
    
    verbose_flag <- if (verbose) "-Verbose" else ""
    
    result <- system2("powershell", 
                      args = c("-ExecutionPolicy", "Bypass", "-File", script_path, verbose_flag),
                      stdout = TRUE, stderr = TRUE, wait = TRUE)
    
    setwd(original_wd)
    
    if (verbose) {
      verbose_log("PowerShell script output:", verbose)
      verbose_log(paste(result, collapse = "\n"), verbose)
    }
    if (!verbose) {
      cat(paste(script_name, "completed.\n"))
    }
    verbose_log(paste(script_name, "completed."), verbose)
    return(result)
  } else {
    cat(paste("PowerShell script not found:", script_path, "\n"))
    verbose_log(paste("PowerShell script not found:", script_path), verbose)
    return(NULL)
  }
}


# Function to run PowerShell script with enhanced error handling
run_powershell_script_with_output <- function(script_name, verbose = FALSE) {
  result <- run_powershell_script(script_name, verbose = verbose)
  if (is.null(result) || length(result) == 0) {
    log_message("No output from PowerShell script", "ERROR")
    return(NULL)
  }
  
  tryCatch({
    json_result <- jsonlite::fromJSON(result)
    if (!is.null(json_result$Error)) {
      log_message(sprintf("Error in PowerShell script: %s", json_result$Error), "ERROR")
      if (!is.null(json_result$StackTrace)) {
        log_message("Stack trace:", "ERROR")
        log_message(json_result$StackTrace, "ERROR")
      }
      return(NULL)
    }
    return(json_result)
  }, error = function(e) {
    log_message(sprintf("Error parsing PowerShell script output: %s", conditionMessage(e)), "ERROR")
    log_message("Raw output:", "ERROR")
    log_message(paste(result, collapse = "\n"), "ERROR")
    return(NULL)
  })
}

# Update handle_import_results function
handle_import_results <- function(import_result) {
  if (!is.null(import_result)) {
    if (!is.null(import_result$Error)) {
      cat("  Error occurred during data import:", import_result$Error, "\n")
    } else {
      cat(paste("  Imported", import_result$GriddedDataStaging, "rows into GriddedDataStaging.\n"))
      cat(paste("  TimeSeries table contains", import_result$TimeSeries, "rows.\n"))
    }
  } else {
    cat("  Warning: No import results reported.\n")
  }
}

# Function to check and create database if necessary
check_database <- function(verbose = FALSE) {
  verbose_log("Checking database...", verbose)
  tryCatch({
    con <- db_connect(database = "master", verbose = verbose)
    db_name <- Sys.getenv("SQL_DATABASE_NAME")
    
    result <- safe_dbGetQuery(con, paste0("SELECT name FROM sys.databases WHERE name = '", db_name, "'"), verbose)
    
    if (nrow(result) == 0) {
      verbose_log(paste(db_name, "database does not exist. Creating it now..."), verbose)
      safe_dbExecute(con, paste0("CREATE DATABASE ", db_name), verbose)
      verbose_log(paste(db_name, "database created."), verbose)
    } else {
      verbose_log(paste(db_name, "database exists."), verbose)
    }
    
    dbDisconnect(con)
  }, error = function(e) {
    stop(paste("Error in check_database:", conditionMessage(e)))
  })
}

# Function to diagnose database tables
diagnose_database_tables <- function(verbose = FALSE) {
  cat("Diagnosing database tables:\n")
  con <- db_connect(verbose = verbose)
  tryCatch({
    tables_to_check <- c("GriddedDataStaging", "TimeSeries", "GriddedData", "ExplorationResults")
    
    for (table in tables_to_check) {
      tryCatch({
        query <- sprintf("SELECT COUNT(*) AS count FROM %s", table)
        result <- dbGetQuery(con, query)
        cat(sprintf("  Rows in %s table: %d\n", table, result$count))
      }, error = function(e) {
        if (grepl("Invalid object name", e$message)) {
          cat(sprintf("  %s table does not exist.\n", table))
        } else {
          cat(sprintf("  Error checking %s table: %s\n", table, conditionMessage(e)))
        }
      })
    }
  }, error = function(e) {
    cat("Error occurred while diagnosing database tables:", conditionMessage(e), "\n")
  }, finally = {
    dbDisconnect(con)
  })
}

# Export all functions
export_functions <- ls()[sapply(ls(), function(x) is.function(get(x)))]