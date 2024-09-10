# data_converter.R

source("utils.R")

process_asc_files <- function(dir, verbose = FALSE) {
  log_message("Processing .asc files...", "INFO")
  output_file <- file.path(dir, "combined_time_series.csv")
  if (file.exists(output_file)) {
    log_message(sprintf("combined_time_series.csv already exists with %d rows. Skipping processing.", count_csv_rows(output_file)), "INFO")
    return(list(file_count = 0, output_file = output_file, row_count = count_csv_rows(output_file)))
  }
  file_list <- list.files(path = dir, pattern = "\\.asc$", full.names = TRUE)
  if (length(file_list) == 0) {
    log_message("No .asc files found in the directory.", "WARNING")
    return(NULL)
  }
  data_list <- lapply(file_list, function(file) {
    log_message(sprintf("Reading file: %s", file), "INFO")
    safe_read_csv(file)
  })
  combined_data <- dplyr::bind_rows(data_list)
  safe_write_csv(combined_data, output_file, verbose)
  log_message(sprintf("Processed %d .asc files. Output saved to %s", length(file_list), output_file), "INFO")
  return(list(file_count = length(file_list), output_file = output_file, row_count = nrow(combined_data)))
}

process_nc_file <- function(dir, verbose = FALSE) {
  log_message("Processing .nc file...", "INFO")
  output_file <- file.path(dir, "gridded_data.csv")
  if (file.exists(output_file)) {
    log_message(sprintf("gridded_data.csv already exists with %d rows. Skipping processing.", count_csv_rows(output_file)), "INFO")
    return(list(file_count = 0, output_file = output_file, row_count = count_csv_rows(output_file)))
  }
  nc_files <- list.files(path = dir, pattern = "\\.nc$", full.names = TRUE)
  if (length(nc_files) == 0) {
    log_message("No .nc files found in the directory.", "WARNING")
    return(NULL)
  }
  nc_file <- nc_files[1]
  log_message(sprintf("Processing file: %s", nc_file), "INFO")
  
  tryCatch({
    nc_data <- ncdf4::nc_open(nc_file)
    var_name <- names(nc_data$var)[1]
    var_data <- ncdf4::ncvar_get(nc_data, var_name)
    df <- as.data.frame(var_data)
    ncdf4::nc_close(nc_data)
    safe_write_csv(df, output_file, verbose)
    log_message(sprintf("Processed file: %s\nOutput saved to %s", nc_file, output_file), "INFO")
    return(list(file_count = 1, output_file = output_file, row_count = nrow(df)))
  }, error = function(e) {
    log_message(sprintf("Error processing NC file: %s", conditionMessage(e)), "ERROR")
    log_message(sprintf("File size: %d bytes", file.size(nc_file)), "INFO")
    log_message(sprintf("File info: %s", file.info(nc_file)), "INFO")
    return(NULL)
  })
}
  nc_file <- nc_files[1]
  log_message(sprintf("Processing file: %s", nc_file), "INFO")
  nc_data <- ncdf4::nc_open(nc_file)
  var_name <- names(nc_data$var)[1]
  var_data <- ncdf4::ncvar_get(nc_data, var_name)
  df <- as.data.frame(var_data)
  ncdf4::nc_close(nc_data)
  safe_write_csv(df, output_file, verbose)
  log_message(sprintf("Processed file: %s\nOutput saved to %s", nc_file, output_file), "INFO")
  return(list(file_count = 1, output_file = output_file, row_count = nrow(df)))
}

main <- function(verbose = FALSE) {
  log_message("Starting data conversion process...", "INFO")
  dir <- "../data/raw/"
  
  asc_result <- process_asc_files(dir, verbose)
  nc_result <- process_nc_file(dir, verbose)
  
  result <- list(asc_result = asc_result, nc_result = nc_result)
  
  # Print summary of results
  log_message("Data Conversion Summary:", "INFO")
  if (!is.null(asc_result)) {
    log_message(sprintf("ASC files processed: %d", asc_result$file_count), "INFO")
    log_message(sprintf("TimeSeries output file: %s", asc_result$output_file), "INFO")
    log_message(sprintf("TimeSeries rows: %d", asc_result$row_count), "INFO")
  } else {
    log_message("No ASC files processed.", "WARNING")
  }
  
  if (!is.null(nc_result)) {
    log_message(sprintf("NC files processed: %d", nc_result$file_count), "INFO")
    log_message(sprintf("GriddedData output file: %s", nc_result$output_file), "INFO")
    log_message(sprintf("GriddedData rows: %d", nc_result$row_count), "INFO")
  } else {
    log_message("No NC files processed.", "WARNING")
  }
  
  log_message("Data conversion process completed.", "INFO")
  return(result)
}

# Run the main function
verbose <- as.logical(Sys.getenv("VERBOSE"))
result <- main(verbose = verbose)

# Return the result for use in other scripts
result