# sql_utils.R

#' Connect to the SQL Database
#'
#' @param verbose Logical, if TRUE, logs connection success message
#' @return A database connection object or NULL if connection fails
db_connect <- function() {
  tryCatch({
    con <- dbConnect(odbc::odbc(),
                     Driver = "ODBC Driver 17 for SQL Server",
                     Server = Sys.getenv("SQL_SERVER_NAME"),
                     Database = Sys.getenv("SQL_DATABASE_NAME"),
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
#' @return A list of query results, or NULL if execution failed
execute_sql_file <- function(con, filename) {
  if (!file.exists(filename)) {
    log_message(sprintf("SQL file not found: %s", filename), "ERROR")
    return(FALSE)
  }
  
  tryCatch({
    sql_content <- paste(readLines(filename), collapse = "\n")
    # Replace placeholder with actual database name
    sql_content <- gsub("\\$\\(SQL_DATABASE_NAME\\)", Sys.getenv("SQL_DATABASE_NAME"), sql_content)
    sql_statements <- unlist(strsplit(sql_content, ";"))
    
    for (statement in sql_statements) {
      statement <- trimws(statement)
      if (nchar(statement) > 0) {
        dbExecute(con, statement)
      }
    }
    
    log_message(sprintf("Executed SQL file: %s", filename))
    TRUE
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
    dbExecute(con, sprintf("DELETE FROM %s", table_name))
    dbWriteTable(con, table_name, data, overwrite = FALSE, append = TRUE, row.names = FALSE)
    
    imported_rows <- dbGetQuery(con, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    log_message(sprintf("Successfully imported %d rows into %s table", imported_rows, table_name))
    imported_rows
  }, error = function(e) {
    log_message(sprintf("Error importing data into %s: %s", table_name, conditionMessage(e)), "ERROR")
    0
  })
}

#' Setup Database
#'
#' @param con Database connection object
#' @return Logical TRUE if setup was successful, FALSE otherwise
setup_database <- function(con) {
  sql_file <- file.path("..", "sql", "setup_database.sql")
  if (!file.exists(sql_file)) {
    log_message(sprintf("SQL file not found: %s", sql_file), "ERROR")
    return(FALSE)
  }
  
  sql_script <- paste(readLines(sql_file), collapse = "\n")
  sql_script <- gsub("\\$\\(SQL_DATABASE_NAME\\)", Sys.getenv("SQL_DATABASE_NAME"), sql_script)
  
  tryCatch({
    dbExecute(con, sql_script)
    log_message("Database setup completed successfully.")
    TRUE
  }, error = function(e) {
    log_message(sprintf("Error executing SQL script %s: %s", sql_file, conditionMessage(e)), "ERROR")
    FALSE
  })
}
