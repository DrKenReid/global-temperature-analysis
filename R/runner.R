# runner.R

# Load utility functions
source("utils.R")

# Load required packages
tryCatch({
  load_required_packages()
}, error = function(e) {
  message("Error loading required packages: ", e$message)
  stop("Please install the missing packages and try again.")
})

main <- function() {
  log_message("Starting data processing pipeline", "INFO")
  
  # Set default environment variables
  set_default_env_variables()
  
  # Connect to the database
  con <- run_pipeline_step("Connecting to database", db_connect)
  
  if (is.null(con)) {
    log_message("Database connection failed. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  # Ensure proper disconnection
  on.exit({
    dbDisconnect(con)
    log_message("Database connection closed.", "INFO")
  }, add = TRUE)
  
  # Download data
  download_result <- run_pipeline_step("Downloading data", download_data)
  if (identical(download_result, FALSE) || is.null(download_result)) {
    log_message("Data download failed. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  # Convert data
  convert_result <- run_pipeline_step("Converting data", convert_data)
  if (identical(convert_result, FALSE) || is.null(convert_result)) {
    log_message("Data conversion failed. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  # Setup database
  setup_result <- run_pipeline_step("Setting up database", execute_sql_file, con, file.path("..", "sql", "setup_database.sql"))
  if (identical(setup_result, FALSE) || is.null(setup_result)) {
    log_message("Database setup failed. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  # Import data
  ts_rows <- run_pipeline_step("Importing TimeSeries data", import_data, 
                               "combined_time_series.csv", con, "TimeSeries")
  gd_rows <- run_pipeline_step("Importing GriddedData", import_data, 
                               "gridded_data.csv", con, "GriddedData")
  
  log_message(sprintf("Imported rows - TimeSeries: %d, GriddedData: %d", ts_rows, gd_rows))
  
  if ((is.null(ts_rows) || ts_rows == 0) && (is.null(gd_rows) || gd_rows == 0)) {
    log_message("No data imported into any table. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  # Execute SQL scripts
  sql_dir <- file.path("..", "sql")
  
  process_result <- run_pipeline_step("Processing data", execute_sql_file, con, file.path(sql_dir, "process_data.sql"))
  if (identical(process_result, FALSE) || is.null(process_result)) {
    log_message("Data processing failed. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  diagnostics_result <- run_pipeline_step("Running diagnostics", execute_sql_file, con, file.path(sql_dir, "run_diagnostics.sql"))
  if (identical(diagnostics_result, FALSE) || is.null(diagnostics_result)) {
    log_message("Diagnostics failed.", "WARNING")
  }
  
  explore_result <- run_pipeline_step("Exploring data", execute_sql_file, con, file.path(sql_dir, "explore_data.sql"))
  if (identical(explore_result, FALSE) || is.null(explore_result)) {
    log_message("Data exploration failed.", "WARNING")
  } else {
    # Retrieve and display exploration results
    exploration_results <- dbGetQuery(con, "SELECT AnalysisName, Result FROM dbo.ExplorationResults ORDER BY ID")
    
    if (nrow(exploration_results) > 0) {
      log_message("Data Exploration Results:", "INFO")
      for (analysis in unique(exploration_results$AnalysisName)) {
        log_message(sprintf("Analysis: %s", analysis), "INFO")
        results <- exploration_results$Result[exploration_results$AnalysisName == analysis]
        for (result in results) {
          log_message(result, "INFO")
        }
        cat("\n")
      }
    } else {
      log_message("No exploration results found in the database.", "WARNING")
    }
  }
  
  log_message("Data processing pipeline completed successfully.", "INFO")
}

# Run the main function
main()
