# data_downloader.R

source("utils.R")

check_required_files <- function(dir, verbose = FALSE) {
  required_files <- c("combined_time_series.csv", "gridded_data.csv")
  existing_files <- required_files[file.exists(file.path(dir, required_files))]
  
  if (length(existing_files) == length(required_files)) {
    log_message("All required files already exist.", "INFO")
    return(TRUE)
  } else {
    missing_files <- setdiff(required_files, existing_files)
    log_message(sprintf("Missing files: %s", paste(missing_files, collapse = ", ")), "INFO")
    return(FALSE)
  }
}

download_files <- function(base_url, pattern, dest_dir, verbose = FALSE) {
  log_message(sprintf("Downloading files from %s", base_url), "INFO")
  tryCatch({
    webpage <- rvest::read_html(base_url)
    links <- webpage %>%
      rvest::html_nodes("a") %>%
      rvest::html_attr("href") %>%
      .[grepl(pattern, .)]
    
    if (length(links) == 0) {
      log_message(sprintf("No files matching pattern %s found at %s", pattern, base_url), "WARNING")
      return(0)
    }
    
    file_urls <- paste0(base_url, links)
    files_existing <- 0
    files_downloaded <- 0
    
    for (file_url in file_urls) {
      file_name <- basename(file_url)
      file_path <- file.path(dest_dir, file_name)
      
      if (file.exists(file_path)) {
        files_existing <- files_existing + 1
        log_message(sprintf("File already exists: %s", file_name), "INFO")
      } else {
        tryCatch({
          httr::GET(file_url, httr::write_disk(file_path, overwrite = TRUE))
          files_downloaded <- files_downloaded + 1
          log_message(sprintf("Downloaded: %s", file_name), "INFO")
        }, error = function(e) {
          log_message(sprintf("Error downloading %s: %s", file_name, conditionMessage(e)), "ERROR")
        })
      }
    }
    
    log_message(sprintf("%d files were already downloaded, %d have now been downloaded.", files_existing, files_downloaded), "INFO")
    return(files_downloaded)
  }, error = function(e) {
    log_message(sprintf("Error occurred while downloading files from %s: %s", base_url, conditionMessage(e)), "ERROR")
    return(0)
  })
}

main <- function(verbose = FALSE) {
  log_message("Starting file check and download process", "INFO")
  
  dest_dir <- "../data/raw/"
  
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
    log_message(sprintf("Created directory: %s", dest_dir), "INFO")
  }
  
  if (check_required_files(dest_dir, verbose)) {
    log_message("All required files already exist. No download necessary.", "INFO")
    return(0)
  }
  
  urls <- list(
    asc = "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/timeseries/",
    nc = "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/gridded/"
  )
  
  total_downloaded <- download_files(urls$asc, "\\.asc$", dest_dir, verbose)
  total_downloaded <- total_downloaded + download_files(urls$nc, "\\.nc$", dest_dir, verbose)
  
  log_message(sprintf("All downloads completed. Total new files downloaded: %d", total_downloaded), "INFO")
  return(total_downloaded)
}

# Run the main function
verbose <- as.logical(Sys.getenv("VERBOSE"))
total_downloaded <- main(verbose = verbose)
log_message(sprintf("Total files downloaded: %d", total_downloaded), "INFO")
total_downloaded  # Return value for the script