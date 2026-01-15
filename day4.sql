/* ============================
   DAY 4: TransferMoney (IBAN inputs) + transaction
   ============================ */

USE Bank_Information_System;
GO

CREATE OR ALTER PROCEDURE dbo.TransferMoney
    @FromIBAN NVARCHAR(34),
    @ToIBAN   NVARCHAR(34),
    @Amount   DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FromAccountId INT;
    DECLARE @ToAccountId   INT;

    -- Validate amount
    IF @Amount IS NULL OR @Amount <= 0
        THROW 50010, 'Amount must be > 0', 1;

    -- Resolve IBANs to account IDs
    SELECT @FromAccountId = id FROM dbo.account WHERE IBAN = @FromIBAN;
    SELECT @ToAccountId   = id FROM dbo.account WHERE IBAN = @ToIBAN;

    IF @FromAccountId IS NULL OR @ToAccountId IS NULL
        THROW 50011, 'Incorrect (sender or recipient) IBAN', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check sufficient balance in sender
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.account_cache
            WHERE account_id = @FromAccountId
              AND balance >= @Amount
        )
        BEGIN
            THROW 50001, 'Insufficient balance', 1;
        END;

        -- Insert debit and credit (two INSERTs required)
        DECLARE @id1 INT = (SELECT ISNULL(MAX(id),0) + 1 FROM dbo.account_detail);
        DECLARE @id2 INT = @id1 + 1;

        INSERT INTO dbo.account_detail (id, account_id, value)
        VALUES (@id1, @FromAccountId, -@Amount);

        INSERT INTO dbo.account_detail (id, account_id, value)
        VALUES (@id2, @ToAccountId, @Amount);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
/*Test*/

EXEC sp_helptext 'dbo.TransferMoney';
GO

SELECT TOP (5) id, IBAN
FROM dbo.account
ORDER BY id;
GO

-- Test 1: invalid sender IBAN (should throw "Incorrect IBAN")
DECLARE @toIBAN NVARCHAR(34);

SELECT TOP (1) @toIBAN = IBAN
FROM dbo.account
ORDER BY id;

EXEC dbo.TransferMoney
    @FromIBAN = N'LT000000000000000000000000000000',
    @ToIBAN   = @toIBAN,
    @Amount   = 10;
GO





