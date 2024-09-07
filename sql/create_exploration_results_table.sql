-- create_exploration_results_table.sql
USE [$(SQL_DATABASE_NAME)]

SET NOCOUNT ON

PRINT 'Creating ExplorationResults table...'

-- Create ExplorationResults table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExplorationResults]') AND type = N'U')
BEGIN
    CREATE TABLE ExplorationResults (
        ResultID INT IDENTITY(1,1) PRIMARY KEY,
        ExplorationName NVARCHAR(100),
        ResultData NVARCHAR(MAX),
        CreatedAt DATETIME DEFAULT GETDATE()
    )
    PRINT 'ExplorationResults table created successfully.'
END
ELSE
BEGIN
    PRINT 'ExplorationResults table already exists.'
END

-- Print some statistics about the ExplorationResults table
PRINT 'ExplorationResults table statistics:'
SELECT 
    'Total Rows' = COUNT(*),
    'Oldest Result' = MIN(CreatedAt),
    'Newest Result' = MAX(CreatedAt)
FROM ExplorationResults
