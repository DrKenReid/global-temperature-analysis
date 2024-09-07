USE [$(SQL_DATABASE_NAME)]

IF OBJECT_ID('dbo.GetTableRowCount', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GetTableRowCount;

CREATE PROCEDURE dbo.GetTableRowCount
    @TableName NVARCHAR(128),
    @RowCount INT OUTPUT
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'SELECT @RowCount = COUNT(*) FROM ' + QUOTENAME(@TableName);
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
END;