/* ============================
   DAY 3: IBAN generation + AddClientWithAccount
   ============================ */

USE Bank_Information_System;
GO

/* ------------------------------------------------------------
   Function: GenerateIBAN
   Requirement: LT + check digits + bank code 70440 + 11-digit account number
   Implements IBAN Mod-97 (ISO 13616) check digits.
*/

CREATE OR ALTER FUNCTION dbo.GenerateIBAN
(
    @accountNumber BIGINT
)
RETURNS NVARCHAR(34)
AS
BEGIN
    DECLARE @bankCode NVARCHAR(5) = N'70440';
    DECLARE @acc NVARCHAR(11) = RIGHT(N'00000000000' + CAST(@accountNumber AS NVARCHAR(20)), 11);

    -- Rearranged for mod97: bank+acc + "LT00"
    DECLARE @rearranged NVARCHAR(100) = @bankCode + @acc + N'LT00';

    -- Replace letters with numbers: L=21, T=29
    DECLARE @numeric NVARCHAR(MAX) = REPLACE(REPLACE(@rearranged, N'L', N'21'), N'T', N'29');

    -- Compute mod97 safely (process digit-by-digit using BIGINT remainder)
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@numeric);
    DECLARE @rem BIGINT = 0;

    WHILE @i <= @len
    BEGIN
        -- rem = (rem*10 + nextDigit) % 97
        SET @rem = (@rem * 10 + (UNICODE(SUBSTRING(@numeric, @i, 1)) - UNICODE('0'))) % 97;
        SET @i += 1;
    END

    DECLARE @check INT = 98 - CONVERT(INT, @rem);
    DECLARE @checkStr NVARCHAR(2) = RIGHT(N'00' + CAST(@check AS NVARCHAR(10)), 2);

    RETURN N'LT' + @checkStr + @bankCode + @acc;
END;
GO



/* ------------------------------------------------------------
   Procedure: AddClientWithAccount
   Requirement: if customer exists -> add another account with new IBAN
   ------------------------------------------------------------ */


CREATE OR ALTER PROCEDURE dbo.AddClientWithAccount
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @phone NVARCHAR(20),
    @city_id INT,
    @address NVARCHAR(200),
    @account_name NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @client_id INT;
    DECLARE @account_id INT;
    DECLARE @cache_id INT;
    DECLARE @iban NVARCHAR(34);

    -- Find existing client
    SELECT @client_id = id
    FROM dbo.client
    WHERE name = @name AND surname = @surname AND phone = @phone;

    -- Create client if not exists
    IF @client_id IS NULL
    BEGIN
        SELECT @client_id = ISNULL(MAX(id), 0) + 1 FROM dbo.client;

        INSERT INTO dbo.client(id, name, surname, phone, city_id, address)
        VALUES (@client_id, @name, @surname, @phone, @city_id, @address);
    END

    -- Create new account id
    SELECT @account_id = ISNULL(MAX(id), 0) + 1 FROM dbo.account;

    -- Generate IBAN (must not be NULL)
    SET @iban = dbo.GenerateIBAN(@account_id);

    IF @iban IS NULL
        THROW 50020, 'IBAN generation failed (GenerateIBAN returned NULL).', 1;

    -- Insert account
    INSERT INTO dbo.account(id, client_id, account_name, IBAN)
    VALUES (@account_id, @client_id, @account_name, @iban);

    -- Insert cache row
    SELECT @cache_id = ISNULL(MAX(id), 0) + 1 FROM dbo.account_cache;

    INSERT INTO dbo.account_cache(id, account_id, balance)
    VALUES (@cache_id, @account_id, 0);
END;
GO

-- Test (optional)



SELECT dbo.GenerateIBAN(7) AS TestIban;
GO

EXEC dbo.AddClientWithAccount
    N'Ali', N'Khan', N'+37062721668', 1, N'Vilnius', N'Ali Main Account';
GO

SELECT * FROM dbo.account ORDER BY id DESC;
SELECT * FROM dbo.account_cache ORDER BY id DESC;
