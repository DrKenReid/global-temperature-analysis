-- TableExists.sql
USE [$(SQL_DATABASE_NAME)]

IF OBJECT_ID('dbo.TableExists', 'FN') IS NOT NULL
    DROP FUNCTION dbo.TableExists;

CREATE FUNCTION dbo.TableExists
(
    @TableName NVARCHAR(128)
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;
    
    IF OBJECT_ID(@TableName, 'U') IS NOT NULL
        SET @Result = 1;
    
    RETURN @Result;
END;
