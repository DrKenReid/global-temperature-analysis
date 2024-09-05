# utils.ps1

# Setup logging
$script:logFile = Join-Path $PSScriptRoot "import_gridded_data.log"

function Start-Logging {
    Start-Transcript -Path $script:logFile -Append
}

function Stop-Logging {
    Stop-Transcript
}

function Write-VerboseLog {
    param([string]$message)
    if ($script:verbose) {
        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - $message"
        Write-Host $logMessage
        Add-Content -Path $script:logFile -Value $logMessage
    }
}

function Test-ModuleInstalled {
    param ([string]$ModuleName)
    return (Get-Module -ListAvailable -Name $ModuleName)
}

function Test-EnvironmentVariables {
    $requiredVars = @("SQL_SERVER_NAME", "SQL_DATABASE_NAME", "SQL_TABLE_NAME", "CSV_PATH")
    $missingVars = $requiredVars | Where-Object { -not (Get-Item env:$_ -ErrorAction SilentlyContinue) }
    
    if ($missingVars) {
        Write-VerboseLog "Error: The following required environment variables are not set: $($missingVars -join ', ')"
        return $false
    }
    return $true
}

function Initialize-BulkCopy {
    param (
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$TableName
    )
    
    $connectionString = "Server=$ServerName;Database=$DatabaseName;Trusted_Connection=True;"
    $bulkCopy = New-Object ("Data.SqlClient.SqlBulkCopy") $connectionString
    $bulkCopy.DestinationTableName = $TableName
    $bulkCopy.BatchSize = 10000
    $bulkCopy.BulkCopyTimeout = 0  # No timeout
    return $bulkCopy
}

function Import-CsvToSql {
    param (
        [string]$CsvPath,
        [Data.SqlClient.SqlBulkCopy]$BulkCopy
    )

    $reader = [System.IO.File]::OpenText($CsvPath)
    $header = $reader.ReadLine()
    $columnNames = $header -split ','

    $dataTable = New-Object System.Data.DataTable
    foreach ($columnName in $columnNames) {
        $dataTable.Columns.Add($columnName)
    }

    $rowCount = 0
    $batchCount = 0
    $reportInterval = 10000  # Report every 10,000 rows

    while ($reader.Peek() -ge 0) {
        $dataTable.Clear()
        
        for ($i = 0; $i -lt $BulkCopy.BatchSize -and $reader.Peek() -ge 0; $i++) {
            $line = $reader.ReadLine()
            $values = $line -split ','
            $dataTable.Rows.Add($values)
            $rowCount++

            if ($rowCount % $reportInterval -eq 0) {
                Write-Progress -Activity "Importing data" -Status "$rowCount rows processed" -PercentComplete -1
                Write-VerboseLog "Processed $rowCount rows"
            }
        }

        $BulkCopy.WriteToServer($dataTable)
        $batchCount++
        Write-VerboseLog "Completed batch $batchCount. Total rows: $rowCount"
    }

    $reader.Close()
    return $rowCount
}