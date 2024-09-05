# utils.R

# Load required packages
required_packages <- c("here", "DBI", "odbc", "R.utils", "readr", "dplyr", "lubridate")

# Function to install and load packages
install_and_load <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    message(paste("Installing package:", package))
    install.packages(package, dependencies = TRUE, quiet = TRUE)
    library(package, character.only = TRUE)
  }
}

# Install and load all required packages
sapply(required_packages, install_and_load)

# Verbose logging function
verbose_log <- function(message, verbose = FALSE) {
  if (verbose) {
    cat(paste0(Sys.time(), " - ", message, "\n"))
  }
}

# Function to check if all required environment variables are set
check_env_variables <- function(required_vars = c("SQL_SERVER_NAME", "SQL_DATABASE_NAME", "SQL_TABLE_NAME", "CSV_PATH")) {
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
  verbose_log(paste("Running R script:", script_path), verbose)
  if (file.exists(script_path)) {
    tryCatch({
      source(script_path, local = new.env())
      verbose_log(paste(script_name, "completed successfully."), verbose)
    }, error = function(e) {
      warning(paste("Error running R script:", conditionMessage(e)))
    })
  } else {
    warning(paste("R script not found:", script_path))
  }
}

# Function to run SQL scripts safely
run_sql_script <- function(script_name, con, verbose = FALSE) {
  script_path <- file.path(here::here(), "..", "sql", script_name)
  verbose_log(paste("Running SQL script:", script_path), verbose)
  if (file.exists(script_path)) {
    tryCatch({
      sql_script <- readLines(script_path)
      sql_script <- paste(sql_script, collapse = "\n")
      
      # Replace placeholders with actual values
      sql_script <- gsub("\\$\\(SQL_DATABASE_NAME\\)", Sys.getenv("SQL_DATABASE_NAME"), sql_script)
      sql_script <- gsub("\\$\\(SQL_TABLE_NAME\\)", Sys.getenv("SQL_TABLE_NAME"), sql_script)
      sql_script <- gsub("\\$\\(CSV_PATH\\)", Sys.getenv("CSV_PATH"), sql_script)
      sql_script <- gsub("\\$\\(VERBOSE\\)", as.character(as.integer(verbose)), sql_script)
      
      # Split the script into individual statements
      statements <- strsplit(sql_script, ";")[[1]]
      
      for (stmt in statements) {
        if (trimws(stmt) != "") {
          safe_dbExecute(con, stmt, verbose)
        }
      }
      verbose_log(paste(script_name, "completed successfully."), verbose)
    }, error = function(e) {
      warning(paste("Error running SQL script:", conditionMessage(e)))
    })
  } else {
    warning(paste("SQL script not found:", script_path))
  }
}

# Function to run PowerShell scripts safely
run_powershell_script <- function(script_name, timeout = 3600, verbose = FALSE) {
  script_path <- file.path(here::here(), "..", "sql", script_name)
  verbose_log(paste("Running PowerShell script:", script_path), verbose)
  
  if (file.exists(script_path)) {
    relative_script_path <- file.path("..", "sql", script_name)
    original_wd <- getwd()
    setwd(here::here())
    
    verbose_flag <- if (verbose) "-Verbose" else ""
    
    result <- tryCatch({
      withTimeout({
        system2("powershell", 
                args = c("-ExecutionPolicy", "Bypass", "-File", relative_script_path, verbose_flag),
                stdout = TRUE, stderr = TRUE, wait = FALSE, timeout = timeout)
      }, timeout = timeout)
    }, TimeoutException = function(ex) {
      warning(paste("PowerShell script execution timed out after", timeout, "seconds."))
      return(NULL)
    }, error = function(e) {
      warning(paste("Error running PowerShell script:", conditionMessage(e)))
      return(NULL)
    })
    
    setwd(original_wd)
    
    if (!is.null(result)) {
      verbose_log("PowerShell script output:", verbose)
      verbose_log(paste(result, collapse = "\n"), verbose)
    }
    verbose_log(paste(script_name, "completed."), verbose)
  } else {
    warning(paste("PowerShell script not found:", script_path))
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