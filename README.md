## 🛠️ Requirements

- R (version 3.6.0 or higher)
- SQL Server (2019 or higher)
- PowerShell (version 5.1 or higher)
- R packages: here, DBI, odbc (install using `install.packages(c("here", "DBI", "odbc"))`)
- SqlServer PowerShell module (install using the instructions below)

### Installing the SqlServer PowerShell Module

Before running the scripts, you need to install the SqlServer PowerShell module. Follow these steps:

1. Open PowerShell as an administrator
2. Run the following command:

```powershell
Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber
```

3. If prompted about installing from an untrusted repository, type 'Y' and press Enter to continue the installation.

This module is required for the PowerShell scripts to interact with SQL Server effectively.

## 🚀 Environment Setup

Before running the scripts, you need to set up the following environment variables:

- `SQL_SERVER_NAME`: The name of your SQL Server instance
- `SQL_DATABASE_NAME`: The name of the database (default: GlobalTemperatureAnalysis)
- `SQL_TABLE_NAME`: The name of the table for gridded data (default: GriddedDataStaging)
- `CSV_PATH`: The path to your gridded data CSV file

### Windows

Run the following commands in PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("SQL_SERVER_NAME", "your_server_name", "User")
[Environment]::SetEnvironmentVariable("SQL_DATABASE_NAME", "GlobalTemperatureAnalysis", "User")
[Environment]::SetEnvironmentVariable("SQL_TABLE_NAME", "GriddedDataStaging", "User")
[Environment]::SetEnvironmentVariable("CSV_PATH", "C:\path\to\your\gridded_data.csv", "User")
```

### macOS and Linux

Add the following lines to your `~/.bash_profile` (macOS) or `~/.bashrc` (Linux):

```bash
export SQL_SERVER_NAME="your_server_name"
export SQL_DATABASE_NAME="GlobalTemperatureAnalysis"
export SQL_TABLE_NAME="GriddedDataStaging"
export CSV_PATH="/path/to/your/gridded_data.csv"
```

Then, run `source ~/.bash_profile` (macOS) or `source ~/.bashrc` (Linux) to apply the changes.
