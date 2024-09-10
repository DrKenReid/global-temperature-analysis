USE [$(SQL_DATABASE_NAME)]

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TimeSeries]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[TimeSeries](
        [Year] INT NOT NULL PRIMARY KEY,
        [Temperature] FLOAT NOT NULL
    )
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GriddedData]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[GriddedData](
        [ID] INT IDENTITY(1,1) PRIMARY KEY,
        [Longitude] FLOAT NOT NULL,
        [Latitude] FLOAT NOT NULL,
        [Temperature] FLOAT NOT NULL
    )
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExplorationResults]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ExplorationResults](
        [ID] INT IDENTITY(1,1) PRIMARY KEY,
        [AnalysisName] NVARCHAR(100) NOT NULL,
        [Result] NVARCHAR(MAX) NOT NULL
    )
END
