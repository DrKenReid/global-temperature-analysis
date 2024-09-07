# import-gridded-data.ps1

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

# Import utility functions
. "$PSScriptRoot\utils.ps1"

try {
    # Check and import SqlServer module
    if (-not (Test-ModuleInstalled -ModuleName "SqlServer")) {
        throw "SqlServer module not found. Please install it manually."
    }
    Import-Module SqlServer -DisableNameChecking

    # Check environment variables
    if (-not (Test-EnvironmentVariables)) {
        throw "Missing required environment variables."
    }

    $ServerName = $env:SQL_SERVER_NAME
    $DatabaseName = $env:SQL_DATABASE_NAME
    $TableName = $env:SQL_TABLE_NAME
    $CsvPath = Join-Path $PSScriptRoot "..\data\raw\gridded_data.csv"

    # Check if CSV file exists
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
    $command.Parameters.Add("@RawData", [System.Data.SqlDbType]::NVarChar, -1) | Out-Null

    # Read and insert CSV data
    $reader = [System.IO.File]::OpenText($CsvPath)
    $rowCount = 0

    while ($null -ne ($line = $reader.ReadLine())) {
        $command.Parameters["@RawData"].Value = $line
        $command.ExecuteNonQuery() | Out-Null
        $rowCount++
    }

    $reader.Close()

    # Verify row count for GriddedDataStaging
    $query = "SELECT COUNT(*) AS TotalRows FROM [$TableName]"
    $command.CommandText = $query
    $griddedDataStagingCount = $command.ExecuteScalar()

    # Check TimeSeries table
    $query = "SELECT COUNT(*) AS TotalRows FROM TimeSeries"
    $command.CommandText = $query
    $timeSeriesCount = $command.ExecuteScalar()

    # Return the row counts as a JSON string
    @{
        GriddedDataStaging = $griddedDataStagingCount
        TimeSeries = $timeSeriesCount
    } | ConvertTo-Json
}
catch {
    @{
        Error = $_.Exception.Message
        StackTrace = $_.ScriptStackTrace
    } | ConvertTo-Json
}
finally {
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}