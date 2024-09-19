# sql_utils.R

#' Connect to the SQL Database and Create Database if It Doesn't Exist
#'
#' @return A database connection object or NULL if connection fails
db_connect <- function() {
  tryCatch({
    # First connect to 'master' database
    con <- dbConnect(odbc::odbc(),
                     Driver = "ODBC Driver 17 for SQL Server",
                     Server = Sys.getenv("SQL_SERVER_NAME"),
                     Database = "master",
                     Trusted_Connection = "Yes")
    
    # Check if database exists
    db_name <- Sys.getenv("SQL_DATABASE_NAME")
    db_exists <- dbGetQuery(con, paste0("SELECT database_id FROM sys.databases WHERE Name = '", db_name, "'"))
    
    if (nrow(db_exists) == 0) {
      # Database does not exist, create it
      dbExecute(con, paste0("CREATE DATABASE [", db_name, "]"))
      log_message(sprintf("Created database %s.", db_name))
    } else {
      log_message(sprintf("Database %s already exists.", db_name))
    }
    
    # Disconnect from 'master' and reconnect to the target database
    dbDisconnect(con)
    
    con <- dbConnect(odbc::odbc(),
                     Driver = "ODBC Driver 17 for SQL Server",
                     Server = Sys.getenv("SQL_SERVER_NAME"),
                     Database = db_name,
                     Trusted_Connection = "Yes")
    log_message("Connected to database successfully.")
    con
  }, error = function(e) {
    log_message(sprintf("Failed to connect to database: %s", conditionMessage(e)), "ERROR")
    NULL  # Return NULL on failure
  })
}

#' Execute SQL File
#'
#' @param con A database connection object
#' @param filename The name of the SQL file to execute
#' @return TRUE if execution was successful, FALSE otherwise
execute_sql_file <- function(con, filename) {
  if (!file.exists(filename)) {
    log_message(sprintf("SQL file not found: %s", filename), "ERROR")
    return(FALSE)
  }
  
  tryCatch({
    sql_content <- paste(readLines(filename), collapse = "\n")
    # Replace placeholder with actual database name
    sql_content <- gsub("\\$\\(SQL_DATABASE_NAME\\)", Sys.getenv("SQL_DATABASE_NAME"), sql_content)
    
    # Execute the entire script with immediate = TRUE
    dbExecute(con, sql_content, immediate = TRUE)
    
    log_message(sprintf("Executed SQL file: %s", filename))
    TRUE  # Indicate success
  }, error = function(e) {
    log_message(sprintf("Error executing SQL script %s: %s", filename, conditionMessage(e)), "ERROR")
    FALSE
  })
}

#' Import Data from CSV to Database
#'
#' @param csv_filename Name of the CSV file (located in data/processed)
#' @param con Database connection object
#' @param table_name Name of the table to import data into
#' @return Number of rows imported, or 0 if import failed
import_data <- function(csv_filename, con, table_name) {
  csv_path <- file.path("..", "data", "processed", csv_filename)
  
  if (!file.exists(csv_path)) {
    log_message(sprintf("File not found: %s", csv_path), "ERROR")
    return(0)
  }
  
  tryCatch({
    data <- read.csv(csv_path)
    
    # Remove duplicate entries if applicable
    if ("Year" %in% colnames(data)) {
      data <- data[!duplicated(data$Year), ]
    }
    
    # Start a database transaction
    dbBegin(con)
    
    # Delete existing data
    delete_result <- dbExecute(con, sprintf("DELETE FROM %s", table_name))
    log_message(sprintf("Deleted %d rows from %s.", delete_result, table_name))
    
    # Log the first few rows of data
    log_message(sprintf("First few rows of data to be imported into %s:", table_name))
    print(head(data))
    
    # Ensure correct data types for GriddedData
    if (table_name == "GriddedData") {
      data$Longitude <- as.numeric(data$Longitude)
      data$Latitude <- as.numeric(data$Latitude)
      data$Time <- as.numeric(data$Time)
      data$Temperature <- as.numeric(data$Temperature)
    }
    
    # Import new data with error capturing
    dbWriteTable(con, table_name, data, overwrite = FALSE, append = TRUE, row.names = FALSE)
    
    # Commit the transaction
    dbCommit(con)
    
    imported_rows <- nrow(data)
    log_message(sprintf("Successfully imported %d rows into %s table", imported_rows, table_name))
    imported_rows
  }, error = function(e) {
    # Rollback in case of error
    dbRollback(con)
    log_message(sprintf("Error importing data into %s: %s", table_name, conditionMessage(e)), "ERROR")
    0
  })
}
