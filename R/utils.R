# utils.R

# Load other utility files
source("sql_utils.R")
source("download_utils.R")
source("conversion_utils.R")

#' Log a Message
#'
#' @param message The message to log
#' @param level The log level (default: "INFO")
log_message <- function(message, level = "INFO") {
  log_entry <- sprintf("[%s] %s: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), level, message)
  cat(log_entry, "\n")
  write(log_entry, file = "pipeline.log", append = TRUE)
}

#' Run a Pipeline Step
#'
#' @param step_name Name of the pipeline step
#' @param fun Function to execute
#' @param ... Additional arguments to pass to the function
#' @return Result of the function execution
run_pipeline_step <- function(step_name, fun, ...) {
  log_message(sprintf("Starting %s", step_name))
  result <- tryCatch(
    fun(...),
    error = function(e) {
      log_message(sprintf("Error in %s: %s", step_name, conditionMessage(e)), "ERROR")
      return(NULL)
    }
  )
  
  if (is.null(result)) {
    log_message(sprintf("%s failed.", step_name), "ERROR")
  } else {
    log_message(sprintf("%s completed successfully.", step_name))
  }
  result
}

#' Set Default Environment Variables
set_default_env_variables <- function() {
  if (Sys.getenv("SQL_SERVER_NAME") == "") Sys.setenv(SQL_SERVER_NAME = "(local)")
  if (Sys.getenv("SQL_DATABASE_NAME") == "") Sys.setenv(SQL_DATABASE_NAME = "GlobalTemperatureAnalysis")
  if (Sys.getenv("VERBOSE") == "") Sys.setenv(VERBOSE = "FALSE")
}

#' Load Required Packages
load_required_packages <- function() {
  required_packages <- c("DBI", "odbc", "dplyr", "httr", "xml2", "ncdf4", "progress", "curl")
  missing_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
  
  if (length(missing_packages) > 0) {
    stop(paste("Missing required packages:", paste(missing_packages, collapse = ", ")))
  }
  
  invisible(lapply(required_packages, library, character.only = TRUE))
}
