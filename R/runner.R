# runner.R

# Set working directory to the script's location
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Source utility functions
source("utils.R")

# Load required packages and set default environment variables
load_required_packages()
set_default_env_variables()

main <- function() {
  log_message("Starting data processing pipeline", "INFO")
  
  con <- db_connect(verbose = TRUE)
  on.exit(dbDisconnect(con))
  
  if (!run_pipeline_step("Downloading data", download_data)) {
    log_message("Data download failed. Stopping pipeline.", "ERROR")
    return(NULL)
  }
  
  if (!run_pipeline_step("Converting data", convert_data)) {
    log_message("Data conversion failed. Stopping pipeline.", "ERROR")
    return(NULL)
  }
  
  if (!run_pipeline_step("Setting up database", setup_database, con)) {
    log_message("Database setup failed. Stopping pipeline.", "ERROR")
    return(NULL)
  }
  
  ts_rows <- run_pipeline_step("Importing TimeSeries data", import_timeseries_data, 
                               file.path("..", "data", "raw", "combined_time_series.csv"), con)
  gd_rows <- run_pipeline_step("Importing GriddedData", import_gridded_data, 
                               file.path("..", "data", "raw", "gridded_data.csv"), con)
  
  if (ts_rows > 0 || gd_rows > 0) {
    run_pipeline_step("Processing data", process_data, con)
    run_pipeline_step("Running diagnostics", run_diagnostics, con)
    run_pipeline_step("Data exploration", explore_data, con)
  } else {
    log_message("No data imported. Skipping processing, diagnostics, and exploration.", "WARNING")
  }
  
  log_message("Data processing pipeline completed.", "INFO")
}

# Run the main function
main()