# import-gridded-data.ps1

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$script:verbose = $Verbose

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Write-Log "Script started"

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
    $CsvPath = Join-Path $PSScriptRoot "..\data\raw\gridded_data.csv"

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

    # Prepare connection
    $connectionString = "Server=$ServerName;Database=$DatabaseName;Trusted_Connection=True;TrustServerCertificate=True;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    # Prepare SQL command
    $insertSql = "INSERT INTO $TableName (RawData) VALUES (@RawData)"
    $command = New-Object System.Data.SqlClient.SqlCommand($insertSql, $connection)
    $command.Parameters.Add("@RawData", [System.Data.SqlDbType]::NVarChar, -1)

    # Read and insert CSV data
    Write-VerboseLog "Reading and inserting CSV data..."
    $reader = [System.IO.File]::OpenText($CsvPath)
    $batchSize = 1000
    $rowCount = 0
    $batchCount = 0

    while ($null -ne ($line = $reader.ReadLine())) {
        $command.Parameters["@RawData"].Value = $line
        $command.ExecuteNonQuery()
        $rowCount++

        if ($rowCount % $batchSize -eq 0) {
            $batchCount++
            Write-VerboseLog "Inserted $rowCount rows (Batch $batchCount)"
        }
    }

    $reader.Close()
    Write-VerboseLog "Data import completed. Total rows inserted: $rowCount"

    # Verify row count
    Write-VerboseLog "Checking total rows in the table..."
    $query = "SELECT COUNT(*) AS TotalRows FROM [$TableName]"
    $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $result = $command.ExecuteScalar()
    Write-VerboseLog "Total rows in ${TableName}: $result"

    Write-VerboseLog "Data import completed successfully."
}
catch {
    Write-Log "An error occurred: $_"
    Write-Log $_.ScriptStackTrace
    
    # Additional error logging
    if ($_.Exception.InnerException) {
        Write-Log "Inner Exception: $($_.Exception.InnerException.Message)"
    }
}
finally {
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}

Write-Log "Script completed"