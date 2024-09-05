# runner.R
source("utils.R")

main <- function(verbose = FALSE) {
  check_env_variables()
  verbose_log("Starting data processing pipeline...", verbose)
  
  run_r_script("data_downloader.R", verbose)
  run_r_script("data_converter.R", verbose)
  
  check_database(verbose)
  
  con <- db_connect(verbose = verbose)
  run_sql_script("1_setup_database_and_timeseries.sql", con, verbose)
  run_sql_script("2_prepare_gridded_data_staging.sql", con, verbose)
  dbDisconnect(con)
  
  run_powershell_script("import-gridded-data.ps1", verbose = verbose)
  
  con <- db_connect(verbose = verbose)
  run_sql_script("3_process_gridded_data.sql", con, verbose)
  dbDisconnect(con)
  
  verbose_log("Data processing pipeline completed.", verbose)
  verbose_log("Next steps: Use Tableau to visualize the cleaned data.", verbose)
}

# Run the main function with verbose logging
main(verbose = TRUE)