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
  
  log_message("Starting data processing pipeline", "INFO")
  
  tryCatch({
    ensure_sql_server()
    install_powershell_module()
    check_database(verbose)
    
    run_pipeline_step("Checking and downloading data", function() {
      total_downloaded <- as.numeric(run_r_script("data_downloader.R", verbose))
      log_message(sprintf("Total files downloaded: %d", total_downloaded), "INFO")
      if (total_downloaded > 0) {
        log_message(sprintf("Downloaded %d new files", total_downloaded), "INFO")
      } else {
        log_message("All required files already exist. No download was necessary.", "INFO")
      }
    })
    
    run_pipeline_step("Converting data", function() {
      conversion_result <- run_r_script("data_converter.R", verbose)
      handle_conversion_results(conversion_result)
    })
    
    run_pipeline_step("Setting up database", function() {
      con <- db_connect(verbose = verbose)
      csv_path <- "../data/raw/combined_time_series.csv"
      run_sql_script("1_setup_database_and_timeseries.sql", con, verbose, csv_path = csv_path)
      run_sql_script("2_prepare_gridded_data_staging.sql", con, verbose)
      
      # Execute SQL utility scripts individually
      tryCatch({
        run_sql_script("GetTableRowCount.sql", con, verbose)
        run_sql_script("TableExists.sql", con, verbose)
        log_message("SQL utility functions created successfully.", "INFO")
      }, error = function(e) {
        log_message(sprintf("Error creating SQL utility functions: %s", conditionMessage(e)), "ERROR")
        log_message("Continuing with the pipeline despite the error.", "WARNING")
      })
      
      exploration_results_script <- "create_exploration_results_table.sql"
      if (file.exists(file.path("..", "sql", exploration_results_script))) {
        run_sql_script(exploration_results_script, con, verbose)
      } else {
        log_message("Warning: create_exploration_results_table.sql not found. ExplorationResults table may not be created.", "WARNING")
      }
      
      dbDisconnect(con)
    })
    
    import_result <- run_pipeline_step("Importing data", function() {
      result <- run_powershell_script_with_output("import-gridded-data.ps1", verbose = verbose)
      if (is.null(result)) {
        log_message("Error occurred during data import. No valid JSON returned.", "ERROR")
        return(FALSE)
      }
      if (!is.null(result$Error)) {
        log_message(sprintf("Error occurred during data import: %s", result$Error), "ERROR")
        return(FALSE)
      }
      handle_import_results(result)
      return(TRUE)
    })
    
    if (import_result) {
      run_pipeline_step("Diagnostic queries", function() {
        con <- db_connect(verbose = verbose)
        
        log_message("Running diagnostic queries", "INFO")
        
        log_message("TimeSeries Table Diagnostics:", "INFO")
        timeseries_results <- run_sql_script("check_timeseries_table.sql", con, verbose)
        print_sql_results(timeseries_results)
        
        log_message("GriddedDataStaging Table Diagnostics:", "INFO")
        griddeddata_results <- run_sql_script("check_griddeddatastaging_table.sql", con, verbose)
        print_sql_results(griddeddata_results)
        
        dbDisconnect(con)
      })
      
      run_pipeline_step("Processing and exploring data", function() {
        con <- db_connect(verbose = verbose)
        tryCatch({
          run_sql_script("3_process_gridded_data.sql", con, verbose)
          run_sql_script("4_data_exploration.sql", con, verbose)
        }, error = function(e) {
          log_message(sprintf("Error in processing and exploring data: %s", conditionMessage(e)), "ERROR")
          log_message("Continuing with the pipeline despite the error.", "WARNING")
        })
        dbDisconnect(con)
      })
      
      run_pipeline_step("Verifying data processing", function() {
        con <- db_connect(verbose = verbose)
        tryCatch({
          results <- run_sql_script("5_verify_data_processing.sql", con, verbose = FALSE)
          verify_data_processing(results, verbose)
        }, error = function(e) {
          log_message(sprintf("Error in verifying data processing: %s", conditionMessage(e)), "ERROR")
          log_message("Continuing with the pipeline despite the error.", "WARNING")
        })
        dbDisconnect(con)
      })
      
      run_pipeline_step("Verifying data consistency", function() {
        con <- db_connect(verbose = verbose)
        
        # Check TimeSeries table
        timeseries_check <- check_data_consistency(con, "TimeSeries", 
                                                   c("Year", "Temperature", "V3", "V4", "V5", "V6", "V7", "V8", "V9", "V10"))
        
        # Check GriddedData table
        griddeddata_check <- check_data_consistency(con, "GriddedData", 
                                                    c("ID", "RowID", "ColumnID", "Value"))
        
        dbDisconnect(con)
        
        if (!timeseries_check || !griddeddata_check) {
          log_message("Data consistency checks failed. Please review the logs and data.", "ERROR")
          return(FALSE)
        }
        
        log_message("All data consistency checks passed.", "INFO")
        return(TRUE)
      })
      
      log_message("Data processing pipeline completed. Data exploration results available in the database", "INFO")
    } else {
      log_message("Data processing pipeline halted due to errors.", "ERROR")
    }
  }, error = function(e) {
    log_message(sprintf("Error in data processing pipeline: %s", conditionMessage(e)), "ERROR")
    log_message("Stack trace:", "ERROR")
    print(sys.calls())
  })
}

# Run the main function
main()