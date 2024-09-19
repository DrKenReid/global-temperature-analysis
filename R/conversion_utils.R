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
      data <- read.table(file, header = TRUE, fill = TRUE, comment.char = "", sep = "", stringsAsFactors = FALSE)
      
      # Check the number of columns and assign names
      if (ncol(data) >= 2) {
        # Assume the first column is Year and second is Temperature
        colnames(data)[1:2] <- c("Year", "Temperature")
        # Select only the first two columns
        data <- data[, c("Year", "Temperature")]
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
    log_message(sprintf("Successfully converted ASC files to %s", output_file))
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
    log_message("No NC files found for conversion.", "ERROR")
    return(FALSE)
  }
  
  tryCatch({
    library(ncdf4)
    library(lubridate)
    
    nc_data <- nc_open(nc_files[1])
    
    # Extract dimensions and variables
    Time <- ncvar_get(nc_data, "time")
    Latitude <- ncvar_get(nc_data, "lat")
    Longitude <- ncvar_get(nc_data, "lon")
    Temperature <- ncvar_get(nc_data, "anom")
    
    # Get full dimension names and sizes
    dim_names_full <- sapply(nc_data$var$anom$dim, function(x) x$name)
    dim_sizes_full <- sapply(nc_data$var$anom$dim, function(x) x$len)
    log_message(sprintf("Full dimension names: %s", paste(dim_names_full, collapse = ", ")))
    log_message(sprintf("Full dimension sizes: %s", paste(dim_sizes_full, collapse = ", ")))
    
    # Adjust dimension names to match Temperature array
    dims_dropped <- which(dim_sizes_full == 1)
    dim_names <- dim_names_full[-dims_dropped]
    dim_temp <- dim(Temperature)
    log_message(sprintf("Adjusted dimension names: %s", paste(dim_names, collapse = ", ")))
    log_message(sprintf("Adjusted dimension sizes: %s", paste(dim_temp, collapse = ", ")))
    
    # Find indices of dimensions
    lon_index <- which(dim_names == "lon")
    lat_index <- which(dim_names == "lat")
    time_index <- which(dim_names == "time")
    
    # Reorder dimensions to [time, lat, lon]
    Temperature_reordered <- aperm(Temperature, c(time_index, lat_index, lon_index))
    
    # Flatten the Temperature array
    Temperature_vector <- as.vector(Temperature_reordered)
    
    # Get time units and convert to numeric days since '1850-01-01'
    time_units <- ncatt_get(nc_data, "time", "units")$value
    time_origin <- sub(".*since ", "", time_units)
    Time_dates <- as.Date(Time, origin = as.Date(time_origin, format = "%Y-%m-%d %H:%M:%S"))
    Time_numeric <- as.numeric(Time_dates - as.Date('1850-01-01'))
    
    # Create coordinate combinations
    coords <- expand.grid(
      Time = Time_numeric,
      Latitude = Latitude,
      Longitude = Longitude
    )
    
    # Ensure lengths match
    if (length(Temperature_vector) != nrow(coords)) {
      log_message("Mismatch between Temperature data and coordinate grid.", "ERROR")
      return(FALSE)
    }
    
    # Combine into data frame
    df <- cbind(coords, Temperature = Temperature_vector)
    
    # Remove missing values
    missing_value_attr <- ncatt_get(nc_data, "anom", "missing_value")
    if (is.null(missing_value_attr$value)) {
      log_message("Missing value attribute not found. Using default -9999.", "WARNING")
      missing_value <- -9999
    } else {
      missing_value <- missing_value_attr$value
    }
    df <- df[df$Temperature != missing_value, ]
    
    # Log the number of rows and columns
    log_message(sprintf("Converted NetCDF to data frame with %d rows and %d columns.", nrow(df), ncol(df)))
    
    # Write to CSV
    write.csv(df, output_file, row.names = FALSE)
    log_message(sprintf("Successfully converted NetCDF file to %s", output_file))
    TRUE
  }, error = function(e) {
    log_message(sprintf("Error converting NC files: %s", conditionMessage(e)), "ERROR")
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
