# PowerShell script to import gridded data into SQL Server

# Configuration
$serverName = ".\KENSQL"
$databaseName = "GlobalTemperatureAnalysis"
$connectionString = "Server=$serverName;Database=$databaseName;Integrated Security=True;"
$filePath = "C:\Users\Ken\temperature-analysis-project\data\raw\gridded_data.csv"
$batchSize = 1000  # Number of rows to insert in a single batch

# Ensure the SQL Server PowerShell module is available
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Host "SqlServer module not found. Installing..."
    Install-Module -Name SqlServer -Force -AllowClobber
}
Import-Module SqlServer

# Function to create a DataTable for batch inserts
function Create-DataTable {
    $dt = New-Object System.Data.DataTable
    $dt.Columns.Add("RawData", [string]) | Out-Null
    return $dt
}

# Main import process
try {
    $startTime = Get-Date
    Write-Host "Starting import process at $startTime"

    # Open the file
    $reader = [System.IO.File]::OpenText($filePath)
    
    # Create SQL connection
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    # Prepare SQL command for batch insert
    $command = $connection.CreateCommand()
    $command.CommandText = "INSERT INTO GriddedDataStaging (RawData) VALUES (@RawData)"
    $command.Parameters.Add("@RawData", [System.Data.SqlDbType]::NVarChar, -1) | Out-Null

    # Create DataTable for batch inserts
    $dataTable = Create-DataTable

    $lineNumber = 0
    $batchCount = 0

    while ($null -ne ($line = $reader.ReadLine())) {
        $lineNumber++

        # Skip header and empty lines
        if ($lineNumber -eq 1 -or [string]::IsNullOrWhiteSpace($line)) { continue }

        # Add row to DataTable
        $dataTable.Rows.Add($line)

        # Perform batch insert when batch size is reached
        if ($dataTable.Rows.Count -eq $batchSize) {
            Write-SqlTableData -ServerInstance $serverName -DatabaseName $databaseName -SchemaName "dbo" -TableName "GriddedDataStaging" -InputData $dataTable
            $dataTable.Clear()
            $batchCount++
            Write-Host "Processed $($batchCount * $batchSize) rows..."
        }
    }

    # Insert any remaining rows
    if ($dataTable.Rows.Count -gt 0) {
        Write-SqlTableData -ServerInstance $serverName -DatabaseName $databaseName -SchemaName "dbo" -TableName "GriddedDataStaging" -InputData $dataTable
    }

    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host "Import completed at $endTime"
    Write-Host "Total duration: $($duration.TotalMinutes) minutes"
    Write-Host "Processed $lineNumber lines in $($batchCount + 1) batches"
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
finally {
    # Cleanup
    if ($reader) { $reader.Close() }
    if ($connection -and $connection.State -eq 'Open') { $connection.Close() }
}

# Verify the import
try {
    $verifyQuery = "SELECT COUNT(*) FROM GriddedDataStaging"
    $result = Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $verifyQuery
    Write-Host "Total rows in GriddedDataStaging: $($result.Column1)"
}
catch {
    Write-Host "Error verifying import: $_" -ForegroundColor Red
}