# utils.R

# Load required packages
load_required_packages <- function() {
  required_packages <- c("here", "DBI", "odbc", "R.utils", "readr", "dplyr", "lubridate")
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
run_sql_script <- function(script_name, con, verbose = FALSE) {
  script_path <- file.path(here::here(), "..", "sql", script_name)
  cat(paste("  Running", script_name, "...\n"))
  if (file.exists(script_path)) {
    tryCatch({
      sql_script <- readLines(script_path)
      sql_script <- paste(sql_script, collapse = "\n")
      
      # Replace placeholders with actual values
      sql_script <- gsub("\\$\\(SQL_DATABASE_NAME\\)", Sys.getenv("SQL_DATABASE_NAME"), sql_script)
      sql_script <- gsub("\\$\\(SQL_TABLE_NAME\\)", Sys.getenv("SQL_TABLE_NAME"), sql_script)
      sql_script <- gsub("\\$\\(VERBOSE\\)", as.character(as.integer(verbose)), sql_script)
      
      # Split the script into individual statements
      statements <- strsplit(sql_script, ";")[[1]]
      
      results <- list()
      for (stmt in statements) {
        if (trimws(stmt) != "") {
          result <- safe_dbGetQuery(con, stmt, verbose)
          if (!is.null(result)) {
            results[[length(results) + 1]] <- result
          }
        }
      }
      cat(paste("  ", script_name, "completed.\n"))
      return(results)
    }, error = function(e) {
      cat(paste("  Error in", script_name, ":", conditionMessage(e), "\n"))
      return(NULL)
    })
  } else {
    cat(paste("  SQL script not found:", script_path, "\n"))
    return(NULL)
  }
}

# Function to print SQL results
print_sql_results <- function(results) {
  for (result in results) {
    if (is.data.frame(result)) {
      print(result)
    } else {
      cat(paste0("  ", result, "\n"))
    }
    cat("\n")
  }
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
  } else {
    cat(paste("PowerShell script not found:", script_path, "\n"))
    verbose_log(paste("PowerShell script not found:", script_path), verbose)
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

# Export all functions
export_functions <- ls()[sapply(ls(), function(x) is.function(get(x)))]