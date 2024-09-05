# import-gridded-data.ps1

$ErrorActionPreference = "Stop"
$script:verbose = $env:GLOBAL_TEMP_VERBOSE -eq "TRUE"

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Start-Logging
Write-VerboseLog "Script started"

try {
    # Check and import SqlServer module
    Write-VerboseLog "Checking for SqlServer module..."
    if (-not (Test-ModuleInstalled -ModuleName "SqlServer")) {
        throw "SqlServer module not found. Please install it manually."
    }
    Import-Module SqlServer
    Write-VerboseLog "SqlServer module imported successfully."

    # Check environment variables
    if (-not (Test-EnvironmentVariables)) {
        throw "Missing required environment variables."
    }

    $ServerName = $env:SQL_SERVER_NAME
    $DatabaseName = $env:SQL_DATABASE_NAME
    $TableName = $env:SQL_TABLE_NAME
    $CsvPath = $env:CSV_PATH

    Write-VerboseLog "Environment variables:"
    Write-VerboseLog "Server Name: $ServerName"
    Write-VerboseLog "Database Name: $DatabaseName"
    Write-VerboseLog "Table Name: $TableName"
    Write-VerboseLog "CSV Path: $CsvPath"

    # Check if CSV file exists
    Write-VerboseLog "Checking if CSV file exists..."
    if (-not (Test-Path $CsvPath)) {
        throw "CSV file not found at path: $CsvPath"
    }

    # Prepare SqlBulkCopy
    Write-VerboseLog "Preparing SqlBulkCopy..."
    $bulkCopy = Initialize-BulkCopy -ServerName $ServerName -DatabaseName $DatabaseName -TableName $TableName

    Write-VerboseLog "DataTable Columns:"
    $dataTable.Columns | ForEach-Object { Write-VerboseLog $_.ColumnName }

    Write-VerboseLog "Destination Table Columns:"
    $query = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$TableName' ORDER BY ORDINAL_POSITION"
    $columns = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -Query $query
    $columns | ForEach-Object { Write-VerboseLog $_.COLUMN_NAME }

    # Start import process
    Write-VerboseLog "Starting CSV import and bulk insert..."
    $startTime = Get-Date
    $rowCount = Import-CsvToSql -CsvPath $CsvPath -BulkCopy $bulkCopy
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-VerboseLog "CSV import and bulk insert completed. Total rows: $rowCount. Time taken: $($duration.TotalSeconds) seconds"

    # Verify row count
    Write-VerboseLog "Checking total rows in the table..."
    $query = "SELECT COUNT(*) AS TotalRows FROM [$TableName]"
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -Query $query
    Write-VerboseLog "Total rows in ${TableName}: $($result.TotalRows)"

    Write-VerboseLog "Data import completed successfully."
}
catch {
    Write-VerboseLog "An error occurred: $_"
    Write-VerboseLog $_.ScriptStackTrace
}
finally {
    if ($bulkCopy) { $bulkCopy.Close() }
    Stop-Logging
}

Write-VerboseLog "Script completed"