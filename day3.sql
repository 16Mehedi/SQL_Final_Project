use Bank_Information_System;
Go;

/* Iban genarating function */

CREATE OR ALTER FUNCTION dbo.GenerateIBAN
(
    @accountNumber BIGINT
)
RETURNS NVARCHAR(34)
AS
BEGIN
    DECLARE @iban NVARCHAR(34);
    DECLARE @acc NVARCHAR(11);

    -- Ensure 11-digit account number
    SET @acc = RIGHT('00000000000' + CAST(@accountNumber AS NVARCHAR), 11);

    -- Simplified IBAN (check digits fixed for project)
    SET @iban = 'LT12' + '70440' + @acc;

    RETURN @iban;
END;
Go;

/* Add customer + automatic account*/


  CREATE OR ALTER PROCEDURE AddClientWithAccount
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @phone NVARCHAR(20),
    @city_id INT,
    @address NVARCHAR(200),
    @account_name NVARCHAR(50)
AS
BEGIN
    DECLARE @client_id INT;
    DECLARE @account_id INT;
    DECLARE @cache_id INT;
    DECLARE @iban NVARCHAR(34);

    /* ---------- CLIENT ---------- */

    -- Check if client exists
    SELECT @client_id = id
    FROM client
    WHERE name = @name AND surname = @surname AND phone = @phone;

    -- Create client if not exists
    IF @client_id IS NULL
    BEGIN
        SELECT @client_id = ISNULL(MAX(id), 0) + 1 FROM client;

        INSERT INTO client(id, name, surname, phone, city_id, address)
        VALUES (@client_id, @name, @surname, @phone, @city_id, @address);
    END;

    /* ---------- ACCOUNT ---------- */

    -- Generate account id
    SELECT @account_id = ISNULL(MAX(id), 0) + 1 FROM account;

    -- Generate IBAN
    SET @iban = dbo.GenerateIBAN(@account_id);

    -- Insert account
    INSERT INTO account(id, client_id, account_name, IBAN)
    VALUES (@account_id, @client_id, @account_name, @iban);

    /* ---------- ACCOUNT CACHE ---------- */

    -- Generate cache id
    SELECT @cache_id = ISNULL(MAX(id), 0) + 1 FROM account_cache;

    INSERT INTO account_cache(id, account_id, balance)
    VALUES (@cache_id, @account_id, 0);
END;
GO

/*testing*/
EXEC AddClientWithAccount
    'Ali',
    'Khan',
    '111111111',
    1,
    'Vilnius',
    'Ali Main Account';


SELECT * FROM client;
SELECT * FROM account;
SELECT * FROM account_cache;
