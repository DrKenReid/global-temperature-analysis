# runner.R

# Set working directory to the script's location
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Source utility functions and other necessary scripts
source("utils.R")

# Load required packages and set default environment variables
load_required_packages()
set_default_env_variables()

main <- function() {
  log_message("Starting data processing pipeline", "INFO")
  
  tryCatch({
    con <- db_connect(verbose = FALSE)
    on.exit(dbDisconnect(con))
    
    if (!run_pipeline_step("Downloading data", download_data)) {
      stop("Data download failed. Stopping pipeline.")
    }
    
    if (!run_pipeline_step("Converting data", convert_data)) {
      stop("Data conversion failed. Stopping pipeline.")
    }
    
    if (!run_pipeline_step("Setting up database", setup_database, con)) {
      stop("Database setup failed. Stopping pipeline.")
    }
    
    ts_rows <- run_pipeline_step("Importing TimeSeries data", import_data, 
                                 "combined_time_series.csv", con, "TimeSeries")
    
    gd_rows <- run_pipeline_step("Importing GriddedData", import_data, 
                                 "gridded_data.csv", con, "GriddedData")
    
    log_message(sprintf("Imported rows - TimeSeries: %d, GriddedData: %d", ts_rows, gd_rows))
    
    if ((is.null(ts_rows) || ts_rows == 0) && (is.null(gd_rows) || gd_rows == 0)) {
      stop("No data imported into any table. Stopping pipeline.")
    }
    
    sql_dir <- file.path("..", "sql")
    run_pipeline_step("Processing data", execute_sql_file, con, file.path(sql_dir, "process_data.sql"))
    run_pipeline_step("Running diagnostics", execute_sql_file, con, file.path(sql_dir, "run_diagnostics.sql"))
    exploration_results <- run_pipeline_step("Data exploration", execute_sql_file, con, file.path(sql_dir, "explore_data.sql"))
    
    if (!is.null(exploration_results)) {
      log_message("Data Exploration Results:")
      for (i in seq_along(exploration_results)) {
        log_message(sprintf("Result set %d:", i))
        print(exploration_results[[i]])
        cat("\n")
      }
    } else {
      log_message("Data exploration failed to produce results.", "WARNING")
    }
    log_message("Data processing pipeline completed successfully.", "INFO")
  }, error = function(e) {
    log_message(sprintf("Pipeline failed: %s", conditionMessage(e)), "ERROR")
  })
}

main()