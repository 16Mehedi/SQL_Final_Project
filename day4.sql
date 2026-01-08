
USE Bank_Information_System;
GO


-- PROCEDURE: TransferMoney
-- Handles money transfers between accounts safely
-- Checks balance, debits sender, credits receiver

CREATE OR ALTER PROCEDURE TransferMoney
    @FromAccountId INT,
    @ToAccountId INT,
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check sufficient balance
        IF NOT EXISTS (
            SELECT 1 FROM account_cache
            WHERE account_id = @FromAccountId
              AND balance >= @Amount
        )
        BEGIN
            THROW 50001, 'Insufficient balance', 1;
        END;

        -- Debit sender account
        INSERT INTO account_detail (id, account_id, value)
        VALUES ((SELECT ISNULL(MAX(id),0)+1 FROM account_detail), @FromAccountId, -@Amount);

        -- Credit receiver account
        INSERT INTO account_detail (id, account_id, value)
        VALUES ((SELECT ISNULL(MAX(id),0)+1 FROM account_detail), @ToAccountId, @Amount);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback transaction if any error occurs
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Re-throw error
        THROW;
    END CATCH
END;
GO


-- TRIGGER: trg_UpdateAccountBalance
-- Automatically updates account_cache.balance
-- whenever a new record is inserted into account_detail

CREATE OR ALTER TRIGGER trg_UpdateAccountBalance
ON account_detail
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ac
    SET ac.balance = ac.balance + i.value
    FROM account_cache ac
    JOIN inserted i
        ON ac.account_id = i.account_id;
END;
GO


-- TESTING SECTION
-- Check balances before transfer
-- Execute a test transfer
-- Check transaction history and updated balances

SELECT * FROM account_cache;
GO

EXEC TransferMoney @FromAccountId = 1, @ToAccountId = 2, @Amount = 200;
GO

SELECT * 
FROM account_detail
WHERE account_id IN (1,2)
ORDER BY id;
GO
