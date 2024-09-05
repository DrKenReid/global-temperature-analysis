# data_downloader.R

source("utils.R")

# Define the URLs and destination directory
urls <- list(
  asc = "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/timeseries/",
  nc = "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/gridded/"
)
dest_dir <- "../data/raw/"

# Function to download files from a given URL
download_files <- function(base_url, pattern, dest_dir, verbose = FALSE) {
  verbose_log(paste("Downloading files from", base_url), verbose)
  tryCatch({
    webpage <- rvest::read_html(base_url)
    links <- webpage %>%
      rvest::html_nodes("a") %>%
      rvest::html_attr("href") %>%
      .[grepl(pattern, .)]
    
    if (length(links) == 0) {
      verbose_log(paste("No files matching pattern", pattern, "found at", base_url), verbose)
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
        verbose_log(paste("File already exists:", file_name), verbose)
      } else {
        httr::GET(file_url, httr::write_disk(file_path, overwrite = TRUE))
        files_downloaded <- files_downloaded + 1
        verbose_log(paste("Downloaded:", file_name), verbose)
      }
    }
    
    verbose_log(paste(files_existing, "files were already downloaded,", files_downloaded, "have now been downloaded."), verbose)
    return(files_downloaded)
  }, error = function(e) {
    verbose_log(paste("Error occurred while downloading files from", base_url, ":", conditionMessage(e)), verbose)
    return(0)
  })
}

# Main function to orchestrate downloads
main <- function(verbose = FALSE) {
  verbose_log("Starting file downloads...", verbose)
  
  # Create destination directory if it does not exist
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
    verbose_log(paste("Created directory:", dest_dir), verbose)
  }
  
  total_downloaded <- download_files(urls$asc, "\\.asc$", dest_dir, verbose)
  total_downloaded <- total_downloaded + download_files(urls$nc, "\\.nc$", dest_dir, verbose)
  verbose_log(paste("All downloads completed. Total new files downloaded:", total_downloaded), verbose)
}

# Run the main function
main(verbose = TRUE)