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
  if (!run_pipeline_step("Downloading data", download_data)) {
    log_message("Data download failed. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  # Convert data
  if (!run_pipeline_step("Converting data", convert_data)) {
    log_message("Data conversion failed. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  # Setup database
  if (!run_pipeline_step("Setting up database", setup_database, con)) {
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
  
  if (!run_pipeline_step("Processing data", execute_sql_file, con, file.path(sql_dir, "process_data.sql"))) {
    log_message("Data processing failed. Stopping pipeline.", "ERROR")
    return(invisible(NULL))
  }
  
  if (!run_pipeline_step("Running diagnostics", execute_sql_file, con, file.path(sql_dir, "run_diagnostics.sql"))) {
    log_message("Diagnostics failed.", "WARNING")
  }
  
  exploration_results <- run_pipeline_step("Exploring data", execute_sql_file, con, file.path(sql_dir, "explore_data.sql"))
  
  if (!is.null(exploration_results) && length(exploration_results) > 0) {
    log_message("Data Exploration Results:")
    for (i in seq_along(exploration_results)) {
      log_message(sprintf("Result set %d:", i))
      print(exploration_results[[i]])
      cat("\n")
    }
  } else {
    log_message("Data exploration did not produce any results.", "WARNING")
  }
  
  log_message("Data processing pipeline completed successfully.", "INFO")
}

# Run the main function
main()
