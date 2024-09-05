# runner.R

# Set working directory to the script's location
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Source utility functions
source("utils.R")

# Load required packages and set default environment variables
load_required_packages()
set_default_env_variables()

main <- function() {
  verbose <- as.logical(Sys.getenv("VERBOSE"))
  
  ensure_sql_server()
  install_powershell_module()
  check_database(verbose)
  
  cat("Starting data processing pipeline...\n\n")
  
  cat("Downloading data:\n")
  total_downloaded <- as.numeric(run_r_script("data_downloader.R", verbose))
  cat(paste("  Total files downloaded:", total_downloaded, "\n\n"))
  
  cat("Converting data:\n")
  run_r_script("data_converter.R", verbose)
  cat("\n")
  
  cat("Setting up database:\n")
  con <- db_connect(verbose = verbose)
  run_sql_script("1_setup_database_and_timeseries.sql", con, verbose)
  run_sql_script("2_prepare_gridded_data_staging.sql", con, verbose)
  dbDisconnect(con)
  cat("\n")
  
  cat("Importing data:\n")
  run_powershell_script("import-gridded-data.ps1", verbose = verbose)
  cat("\n")
  
  cat("Processing and exploring data:\n")
  con <- db_connect(verbose = verbose)
  run_sql_script("3_process_gridded_data.sql", con, verbose)
  run_sql_script("4_data_exploration.sql", con, verbose)
  dbDisconnect(con)
  cat("\n")
  
  cat("Verifying data processing:\n")
  con <- db_connect(verbose = verbose)
  results <- run_sql_script("5_verify_data_processing.sql", con, verbose = TRUE)
  print_sql_results(results)
  dbDisconnect(con)
  cat("\n")
  
  cat("Verifying data exploration results:\n")
  con <- db_connect(verbose = verbose)
  results <- run_sql_script("6_verify_data_exploration.sql", con, verbose = TRUE)
  print_sql_results(results)
  dbDisconnect(con)
  cat("\n")
  
  cat("Data processing pipeline completed. Data exploration results available in the database\n")
}

# Run the main function
main()