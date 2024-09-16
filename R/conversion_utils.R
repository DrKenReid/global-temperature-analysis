# conversion_utils.R

#' Convert ASC Files to CSV
#'
#' @param raw_dir Directory containing raw ASC files
#' @param output_file Path to output CSV file
#' @return Logical indicating success or failure
# conversion_utils.R
convert_asc_to_csv <- function(raw_dir, output_file) {
  asc_files <- list.files(raw_dir, pattern = "\\.asc$", full.names = TRUE)
  if (length(asc_files) == 0) {
    log_message("No ASC files found for conversion.", "ERROR")
    return(FALSE)
  }
  
  tryCatch({
    ts_data_list <- lapply(asc_files, function(file) {
      # Read the file with appropriate parameters
      data <- read.table(file, header = FALSE, fill = TRUE, comment.char = "", sep = "")
      
      # Check if the data has at least two columns
      if (ncol(data) >= 2) {
        # Ensure only the first two columns are used
        data <- data[, 1:2]
        colnames(data) <- c("Year", "Temperature")
        return(data)
      } else {
        log_message(sprintf("File %s does not have at least two columns. Skipping.", basename(file)), "WARNING")
        return(NULL)
      }
    })
    
    # Remove NULL entries from the list
    ts_data_list <- Filter(Negate(is.null), ts_data_list)
    
    if (length(ts_data_list) == 0) {
      log_message("No valid ASC files to process after filtering.", "ERROR")
      return(FALSE)
    }
    
    # Combine all data frames into one
    ts_data <- do.call(rbind, ts_data_list)
    
    # Write the combined data to CSV
    write.csv(ts_data, output_file, row.names = FALSE)
    TRUE
  }, error = function(e) {
    log_message(sprintf("Error converting ASC files: %s", conditionMessage(e)), "ERROR")
    FALSE
  })
}


#' Convert NC File to CSV
#'
#' @param raw_dir Directory containing raw NC file
#' @param output_file Path to output CSV file
#' @return Logical indicating success or failure
convert_nc_to_csv <- function(raw_dir, output_file) {
  nc_files <- list.files(raw_dir, pattern = "\\.nc$", full.names = TRUE)
  if (length(nc_files) == 0) {
    log_message("No NC file found for conversion.", "ERROR")
    return(FALSE)
  }
  
  tryCatch({
    nc <- ncdf4::nc_open(nc_files[1])
    on.exit(ncdf4::nc_close(nc))
    
    lon <- ncdf4::ncvar_get(nc, "lon")
    lat <- ncdf4::ncvar_get(nc, "lat")
    time <- ncdf4::ncvar_get(nc, "time")
    temp <- ncdf4::ncvar_get(nc, names(nc$var)[1])
    
    df <- expand.grid(Longitude = lon, Latitude = lat, Time = time)
    df$Temperature <- as.vector(temp)
    
    write.csv(df, output_file, row.names = FALSE)
    TRUE
  }, error = function(e) {
    log_message(sprintf("Error converting NC file: %s", conditionMessage(e)), "ERROR")
    FALSE
  })
}

#' Convert Raw Data to CSV Format
#'
#' @return Logical TRUE if conversion was successful, FALSE otherwise
convert_data <- function() {
  raw_dir <- file.path("..", "data", "raw")
  processed_dir <- file.path("..", "data", "processed")
  dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)
  
  timeseries_csv <- file.path(processed_dir, "combined_time_series.csv")
  gridded_csv <- file.path(processed_dir, "gridded_data.csv")
  
  ts_success <- convert_asc_to_csv(raw_dir, timeseries_csv)
  nc_success <- convert_nc_to_csv(raw_dir, gridded_csv)
  
  if (ts_success && nc_success) {
    log_message("Data conversion completed successfully.")
    TRUE
  } else {
    log_message("Data conversion failed.", "ERROR")
    FALSE
  }
}
