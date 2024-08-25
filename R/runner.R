# runner.R

# Function to install and load packages
install_and_load <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    cat("Installing package:", package, "\n")
    install.packages(package, dependencies = TRUE, quiet = TRUE)
    library(package, character.only = TRUE)
  }
}

# Install and load required packages
install_and_load("here")
install_and_load("DBI")
install_and_load("odbc")

# Print the current working directory
cat("Current working directory:", getwd(), "\n")

# Print the project root directory as determined by here
cat("Project root directory:", here::here(), "\n")

# Function to run R scripts
run_r_script <- function(script_name) {
  script_path <- file.path(here::here(), script_name)
  cat("Looking for script at:", script_path, "\n")
  if (file.exists(script_path)) {
    cat("Running", script_name, "...\n")
    source(script_path)
    cat(script_name, "completed.\n\n")
  } else {
    cat("Error:", script_name, "not found at", script_path, "\n")
  }
}

# Function to run SQL scripts
run_sql_script <- function(script_name) {
  script_path <- file.path(here::here(), "sql", script_name)
  cat("Running SQL script:", script_path, "\n")
  
  # Connect to the database
  con <- dbConnect(odbc::odbc(), 
                   Driver = "SQL Server", 
                   Server = "KENSQL", 
                   Database = "GlobalTemperatureAnalysis", 
                   Trusted_Connection = "Yes")
  
  # Read the SQL script
  sql_script <- readLines(script_path)
  sql_script <- paste(sql_script, collapse = "\n")
  
  # Execute the SQL script
  tryCatch({
    dbExecute(con, sql_script)
    cat(script_name, "completed successfully.\n\n")
  }, error = function(e) {
    cat("Error executing", script_name, ":", e$message, "\n")
  })
  
  # Close the connection
  dbDisconnect(con)
}

# Function to run PowerShell script
run_powershell_script <- function(script_name) {
  script_path <- file.path(here::here(), "sql", script_name)
  cat("Running PowerShell script:", script_path, "\n")
  
  system(paste("powershell -ExecutionPolicy Bypass -File", script_path), intern = TRUE)
  
  cat(script_name, "completed.\n\n")
}

# Main execution
main <- function() {
  cat("Starting data processing pipeline...\n\n")
  
  # Run R scripts
  run_r_script("data_downloader.R")
  run_r_script("data_converter.R")
  
  # Run SQL and PowerShell scripts
  run_sql_script("store-and-preprocess.sql")
  run_powershell_script("prep-wide-climate-data.ps1")
  run_sql_script("store-and-preprocess 2.sql")
  run_sql_script("clean.sql")
  
  cat("Data processing pipeline completed.\n")
  cat("Next steps: Use Tableau to visualize the cleaned data.\n")
}

# Run the main function
main()