/* ============================================================
   TASK 4a: IBAN generation function
   ============================================================ */

CREATE OR ALTER FUNCTION dbo.GenerateIBAN (@accountNumber BIGINT)
RETURNS NVARCHAR(34)
AS
BEGIN
    DECLARE @bankCode NVARCHAR(5) = N'70440';
    DECLARE @acc NVARCHAR(11) = RIGHT(N'00000000000' + CAST(@accountNumber AS NVARCHAR(20)), 11);
    DECLARE @rearranged NVARCHAR(100) = @bankCode + @acc + N'LT00';
    DECLARE @numeric NVARCHAR(MAX) = REPLACE(REPLACE(@rearranged, N'L', N'21'), N'T', N'29');

    DECLARE @i INT = 1, @len INT = LEN(@numeric), @rem BIGINT = 0;
    WHILE @i <= @len
    BEGIN
        SET @rem = (@rem * 10 + (UNICODE(SUBSTRING(@numeric, @i, 1)) - UNICODE('0'))) % 97;
        SET @i += 1;
    END

    DECLARE @check INT = 98 - CONVERT(INT, @rem);
    RETURN N'LT' + RIGHT(N'00' + CAST(@check AS NVARCHAR(10)), 2) + @bankCode + @acc;
END;
GO


/* ============================================================
   TASK 4b: Add customer with account
   ============================================================ */

CREATE OR ALTER PROCEDURE dbo.AddClientWithAccount
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @phone NVARCHAR(20),
    @city_id INT,
    @address NVARCHAR(200),
    @account_name NVARCHAR(50)
AS
BEGIN
    DECLARE @client_id INT, @account_id INT, @cache_id INT, @iban NVARCHAR(34);

    SELECT @client_id = id
    FROM dbo.client
    WHERE name = @name AND surname = @surname AND phone = @phone;

    IF @client_id IS NULL
    BEGIN
        SELECT @client_id = ISNULL(MAX(id), 0) + 1 FROM dbo.client;
        INSERT INTO dbo.client(id, name, surname, phone, city_id, address)
        VALUES (@client_id, @name, @surname, @phone, @city_id, @address);
    END

    SELECT @account_id = ISNULL(MAX(id), 0) + 1 FROM dbo.account;
    SET @iban = dbo.GenerateIBAN(@account_id);

    INSERT INTO dbo.account(id, client_id, account_name, IBAN)
    VALUES (@account_id, @client_id, @account_name, @iban);

    SELECT @cache_id = ISNULL(MAX(id), 0) + 1 FROM dbo.account_cache;
    INSERT INTO dbo.account_cache(id, account_id, balance)
    VALUES (@cache_id, @account_id, 0);
END;
GO