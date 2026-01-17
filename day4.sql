/* ============================================================
   TASK 4c & TASK 4d: Transfer with transaction
   ============================================================ */
USE Bank_Information_System;
GO

CREATE OR ALTER PROCEDURE dbo.TransferMoney
    @FromIBAN NVARCHAR(34),
    @ToIBAN   NVARCHAR(34),
    @Amount   DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FromAccountId INT, @ToAccountId INT;

    IF @Amount IS NULL OR @Amount <= 0
    BEGIN
        RAISERROR('Amount must be > 0', 16, 1);
        RETURN;
    END

    SELECT @FromAccountId = id FROM dbo.account WHERE IBAN = @FromIBAN;
    SELECT @ToAccountId   = id FROM dbo.account WHERE IBAN = @ToIBAN;

    IF @FromAccountId IS NULL OR @ToAccountId IS NULL
    BEGIN
        RAISERROR('Incorrect IBAN', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.account_cache
            WHERE account_id = @FromAccountId
              AND balance >= @Amount
        )
        BEGIN
            RAISERROR('Insufficient balance', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

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

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSev INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR(@ErrMsg, @ErrSev, @ErrState);
    END CATCH
END;
GO
