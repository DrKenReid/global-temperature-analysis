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
    $TableName = "TimeSeries"
    $CsvPath = Join-Path $PSScriptRoot "..\data\raw\combined_time_series.csv"

    # Check if CSV file exists
    if (-not (Test-Path $CsvPath)) {
        throw "CSV file not found at path: $CsvPath"
    }

    # Prepare connection
    $connectionString = "Server=$ServerName;Database=$DatabaseName;Trusted_Connection=True;TrustServerCertificate=True;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    # Prepare SQL command
    $insertSql = "INSERT INTO $TableName (Year, Temperature, V3, V4, V5, V6, V7, V8, V9, V10) VALUES (@Year, @Temperature, @V3, @V4, @V5, @V6, @V7, @V8, @V9, @V10)"
    $command = New-Object System.Data.SqlClient.SqlCommand($insertSql, $connection)
    $command.Parameters.Add("@Year", [System.Data.SqlDbType]::Int) | Out-Null
    $command.Parameters.Add("@Temperature", [System.Data.SqlDbType]::Float) | Out-Null
    $command.Parameters.Add("@V3", [System.Data.SqlDbType]::Float) | Out-Null
    $command.Parameters.Add("@V4", [System.Data.SqlDbType]::Float) | Out-Null
    $command.Parameters.Add("@V5", [System.Data.SqlDbType]::Float) | Out-Null
    $command.Parameters.Add("@V6", [System.Data.SqlDbType]::Float) | Out-Null
    $command.Parameters.Add("@V7", [System.Data.SqlDbType]::VarChar, 50) | Out-Null
    $command.Parameters.Add("@V8", [System.Data.SqlDbType]::VarChar, 50) | Out-Null
    $command.Parameters.Add("@V9", [System.Data.SqlDbType]::VarChar, 50) | Out-Null
    $command.Parameters.Add("@V10", [System.Data.SqlDbType]::VarChar, 50) | Out-Null

    # Read and insert CSV data
    $reader = [System.IO.File]::OpenText($CsvPath)
    $reader.ReadLine() # Skip header
    $rowCount = 0

    while ($null -ne ($line = $reader.ReadLine())) {
        $fields = $line -split ','
        if ($fields.Count -ge 6) {
            $command.Parameters["@Year"].Value = [int]$fields[0]
            $command.Parameters["@Temperature"].Value = [float]$fields[1]
            $command.Parameters["@V3"].Value = if ($fields[2] -eq '-999') { [DBNull]::Value } else { [float]$fields[2] }
            $command.Parameters["@V4"].Value = if ($fields[3] -eq '-999') { [DBNull]::Value } else { [float]$fields[3] }
            $command.Parameters["@V5"].Value = if ($fields[4] -eq '-999') { [DBNull]::Value } else { [float]$fields[4] }
            $command.Parameters["@V6"].Value = if ($fields[5] -eq '-999') { [DBNull]::Value } else { [float]$fields[5] }
            $command.Parameters["@V7"].Value = if ($fields.Count > 6 -and $fields[6] -ne '') { $fields[6] } else { [DBNull]::Value }
            $command.Parameters["@V8"].Value = if ($fields.Count > 7 -and $fields[7] -ne '') { $fields[7] } else { [DBNull]::Value }
            $command.Parameters["@V9"].Value = if ($fields.Count > 8 -and $fields[8] -ne '') { $fields[8] } else { [DBNull]::Value }
            $command.Parameters["@V10"].Value = if ($fields.Count > 9 -and $fields[9] -ne '') { $fields[9] } else { [DBNull]::Value }
            $command.ExecuteNonQuery() | Out-Null
            $rowCount++
        }
    }

    $reader.Close()

    # Return JSON result
    @{
        TimeSeries = $rowCount
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