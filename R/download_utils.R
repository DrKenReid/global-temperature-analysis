# download_utils.R

#' Download a Single File
#'
#' @param url Full URL of the file to download
#' @param destfile Destination file path
#' @param pb Progress bar object
#' @return Logical indicating success or failure
download_single_file <- function(url, destfile, pb) {
  if (file.exists(destfile)) {
    pb$tick()
    return(TRUE)
  }
  tryCatch({
    download.file(url, destfile, mode = "wb", quiet = TRUE)
    pb$tick()
    TRUE
  }, error = function(e) {
    log_message(sprintf("Error downloading %s: %s", url, conditionMessage(e)), "ERROR")
    pb$tick()
    FALSE
  })
}

#' Get File List from URL
#'
#' @param url URL to fetch file list from
#' @param file_extension File extension to filter (e.g., ".asc" or ".nc")
#' @return Character vector of file names
get_file_list <- function(url, file_extension) {
  tryCatch({
    page_content <- httr::GET(url)
    httr::stop_for_status(page_content)
    httr::content(page_content, "text") |>
      xml2::read_html() |>
      xml2::xml_find_all(sprintf("//a[contains(@href, '%s')]", file_extension)) |>
      xml2::xml_attr("href")
  }, error = function(e) {
    log_message(sprintf("Error fetching file list from %s: %s", url, conditionMessage(e)), "ERROR")
    character(0)
  })
}

#' Extract Date from NC File Name
#'
#' @param filename NC file name
#' @return Date object or NA if extraction fails
extract_date_from_nc_filename <- function(filename) {
  date_string <- sub(".*_e(\\d{6})_.*", "\\1", filename)
  if (date_string == filename) {
    log_message(sprintf("Failed to extract date from filename: %s", filename), "WARNING")
    return(NA)
  }
  tryCatch({
    as.Date(paste0(date_string, "01"), format = "%Y%m%d")
  }, error = function(e) {
    log_message(sprintf("Error parsing date from %s: %s", date_string, conditionMessage(e)), "ERROR")
    NA
  })
}

#' Download ASC Files
#'
#' @param url Base URL for ASC files
#' @param download_dir Directory to save downloaded files
#' @return Logical vector indicating success or failure for each file
download_asc_files <- function(url, download_dir) {
  asc_files <- get_file_list(url, ".asc")
  if (length(asc_files) == 0) {
    log_message("No ASC files found to download.", "ERROR")
    return(logical(0))
  }
  
  pb <- progress::progress_bar$new(total = length(asc_files), format = "Downloading ASC files [:bar] :percent")
  vapply(asc_files, function(file) {
    download_single_file(paste0(url, file), file.path(download_dir, file), pb)
  }, logical(1))
}

#' Download NC File
#'
#' @param url Base URL for NC files
#' @param download_dir Directory to save downloaded files
#' @return Logical indicating success or failure
download_nc_file <- function(url, download_dir) {
  nc_files <- get_file_list(url, ".nc")
  if (length(nc_files) == 0) {
    log_message("No NC files found to download.", "ERROR")
    return(FALSE)
  }
  
  nc_dates <- sapply(nc_files, extract_date_from_nc_filename)
  latest_nc_file <- nc_files[which.max(nc_dates)]
  
  pb <- progress::progress_bar$new(total = 1, format = "Downloading NC file [:bar] :percent")
  download_single_file(paste0(url, latest_nc_file), file.path(download_dir, latest_nc_file), pb)
}

#' Download Required Data Files
#'
#' @return Logical TRUE if download was successful, FALSE otherwise
download_data <- function() {
  base_url <- "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/"
  timeseries_url <- paste0(base_url, "timeseries/")
  gridded_url <- paste0(base_url, "gridded/")
  
  download_dir <- file.path("..", "data", "raw")
  dir.create(download_dir, showWarnings = FALSE, recursive = TRUE)
  
  asc_success <- download_asc_files(timeseries_url, download_dir)
  nc_success <- download_nc_file(gridded_url, download_dir)
  
  log_message(sprintf("Downloaded %d/%d ASC files and %s NC file", 
                      sum(asc_success), length(asc_success), 
                      if (nc_success) "1/1" else "0/1"))
  
  all(asc_success) && nc_success
}
