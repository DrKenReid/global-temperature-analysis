# Function to install and load packages
install_and_load <- function(package) {
  if (!require(package, character.only = TRUE)) {
    install.packages(package)
    library(package, character.only = TRUE)
  }
}

# Install and load required packages
packages <- c('data.table', 'ncdf4', 'raster')
sapply(packages, install_and_load)

# Set working directory
dir <- "../data/raw/"

# Process .asc files
process_asc_files <- function(dir) {
  cat("Processing .asc files...\n")
  file_list <- list.files(path = dir, pattern = "\\.asc$", full.names = TRUE)
  if (length(file_list) == 0) {
    cat("No .asc files found in the directory.\n")
    return(NULL)
  }
  data_list <- lapply(file_list, fread, fill = TRUE)
  combined_data <- rbindlist(data_list, fill = TRUE)
  output_file <- file.path(dir, "combined_time_series.csv")
  fwrite(combined_data, output_file)
  cat("Processed", length(file_list), ".asc files. Output saved to", output_file, "\n")
}

# Process .nc file
process_nc_file <- function(dir) {
  cat("Processing .nc file...\n")
  nc_files <- list.files(path = dir, pattern = "\\.nc$", full.names = TRUE)
  if (length(nc_files) == 0) {
    cat("No .nc files found in the directory.\n")
    return(NULL)
  }
  nc_file <- nc_files[1]
  nc_data <- nc_open(nc_file)
  var_name <- names(nc_data$var)[1]
  var_data <- ncvar_get(nc_data, var_name)
  df <- as.data.frame(var_data)
  nc_close(nc_data)
  output_file <- file.path(dir, "gridded_data.csv")
  write.csv(df, output_file, row.names = FALSE)
  cat("Processed file:", nc_file, "\nOutput saved to", output_file, "\n")
}

# Main execution
main <- function() {
  process_asc_files(dir)
  process_nc_file(dir)
  cat("All processing completed.\n")
}

# Run the main function
main()