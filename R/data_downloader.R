# Function to install and load packages
install_and_load <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    cat("Installing package:", package, "\n")
    install.packages(package, dependencies = TRUE, quiet = TRUE)
    library(package, character.only = TRUE)
  }
}

# Install and load required packages
packages <- c("httr", "rvest")
sapply(packages, install_and_load)

# Define the URLs and destination directory
urls <- list(
  asc = "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/timeseries/",
  nc = "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6/access/gridded/"
)
dest_dir <- "../data/raw/"

# Create destination directory if it does not exist
if (!dir.exists(dest_dir)) {
  dir.create(dest_dir, recursive = TRUE)
  cat("Created directory:", dest_dir, "\n")
}

# Function to download files from a given URL
download_files <- function(base_url, pattern, dest_dir) {
  tryCatch({
    # Read the webpage
    webpage <- read_html(base_url)
    
    # Extract links that match the file extension pattern
    links <- webpage %>%
      html_nodes("a") %>%
      html_attr("href") %>%
      .[grepl(pattern, .)]
    
    if (length(links) == 0) {
      cat("No files matching pattern", pattern, "found at", base_url, "\n")
      return()
    }
    
    # Define the full URLs of the files
    file_urls <- paste0(base_url, links)
    
    # Download each file
    for (file_url in file_urls) {
      file_name <- basename(file_url)
      file_path <- file.path(dest_dir, file_name)
      
      # Check if file already exists
      if (file.exists(file_path)) {
        cat("File already exists, skipping:", file_name, "\n")
      } else {
        # Download file
        GET(file_url, write_disk(file_path, overwrite = TRUE))
        cat("Downloaded:", file_name, "\n")
      }
    }
  }, error = function(e) {
    cat("Error occurred while downloading files from", base_url, ":", conditionMessage(e), "\n")
  })
}

# Main function to orchestrate downloads
main <- function() {
  cat("Starting file downloads...\n")
  download_files(urls$asc, "\\.asc$", dest_dir)
  download_files(urls$nc, "\\.nc$", dest_dir)
  cat("All downloads completed.\n")
}

# Run the main function
main()