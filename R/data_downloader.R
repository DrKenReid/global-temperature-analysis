# data_downloader.R

download_data <- function() {
  base_url <- "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/"
  timeseries_url <- paste0(base_url, "timeseries/")
  gridded_url <- paste0(base_url, "gridded/")
  
  download_dir <- file.path("..", "data", "raw")
  dir.create(download_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Download timeseries data
  timeseries_files <- c("aravg.ann.land_ocean.90S.90N.v6.0.0.202407.asc")
  for (file in timeseries_files) {
    download.file(paste0(timeseries_url, file), file.path(download_dir, file), mode = "wb")
  }
  
  # Download gridded data
  gridded_files <- c("NOAAGlobalTemp_v6.0.0_gridded_s185001_e202407_c20240806T153047.nc")
  for (file in gridded_files) {
    download.file(paste0(gridded_url, file), file.path(download_dir, file), mode = "wb")
  }
  
  log_message("Data download completed.", "INFO")
}