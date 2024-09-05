# data_converter.R

source("utils.R")

# Set working directory
dir <- "../data/raw/"

# Process .asc files
process_asc_files <- function(dir, verbose = FALSE) {
  verbose_log("Processing .asc files...", verbose)
  output_file <- file.path(dir, "combined_time_series.csv")
  if (file.exists(output_file)) {
    verbose_log("combined_time_series.csv already exists. Skipping processing.", verbose)
    return(NULL)
  }
  file_list <- list.files(path = dir, pattern = "\\.asc$", full.names = TRUE)
  if (length(file_list) == 0) {
    verbose_log("No .asc files found in the directory.", verbose)
    return(NULL)
  }
  data_list <- lapply(file_list, function(file) {
    verbose_log(paste("Reading file:", file), verbose)
    safe_read_csv(file)
  })
  combined_data <- dplyr::bind_rows(data_list)
  safe_write_csv(combined_data, output_file, verbose)
  verbose_log(paste("Processed", length(file_list), ".asc files. Output saved to", output_file), verbose)
}

# Process .nc file
process_nc_file <- function(dir, verbose = FALSE) {
  verbose_log("Processing .nc file...", verbose)
  output_file <- file.path(dir, "gridded_data.csv")
  if (file.exists(output_file)) {
    verbose_log("gridded_data.csv already exists. Skipping processing.", verbose)
    return(NULL)
  }
  nc_files <- list.files(path = dir, pattern = "\\.nc$", full.names = TRUE)
  if (length(nc_files) == 0) {
    verbose_log("No .nc files found in the directory.", verbose)
    return(NULL)
  }
  nc_file <- nc_files[1]
  verbose_log(paste("Processing file:", nc_file), verbose)
  nc_data <- ncdf4::nc_open(nc_file)
  var_name <- names(nc_data$var)[1]
  var_data <- ncdf4::ncvar_get(nc_data, var_name)
  df <- as.data.frame(var_data)
  ncdf4::nc_close(nc_data)
  safe_write_csv(df, output_file, verbose)
  verbose_log(paste("Processed file:", nc_file, "\nOutput saved to", output_file), verbose)
}

# Main execution
main <- function(verbose = FALSE) {
  verbose_log("Starting data conversion process...", verbose)
  process_asc_files(dir, verbose)
  process_nc_file(dir, verbose)
  verbose_log("All processing completed.", verbose)
}

# Run the main function
main(verbose = TRUE)

# cleanup
closeAllConnections()