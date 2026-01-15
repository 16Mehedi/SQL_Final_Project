/* ============================
   DAY 5: Triggers + Get_by_cities + Test city 14
   ============================ */

USE Bank_Information_System;
GO

/* ------------------------------------------------------------
   Trigger: Recalculate account_cache after INSERT/UPDATE/DELETE on account_detail
   Requirement: recalculate balance each time (PDF page 2) :contentReference[oaicite:8]{index=8}
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER dbo.trg_account_detail_recalc_cache
ON dbo.account_detail
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH affected AS
    (
        SELECT account_id FROM inserted
        UNION
        SELECT account_id FROM deleted
    ),
    totals AS
    (
        SELECT
            a.account_id,
            CAST(ISNULL(SUM(ad.value), 0) AS DECIMAL(18,2)) AS new_balance
        FROM affected a
        LEFT JOIN dbo.account_detail ad
            ON ad.account_id = a.account_id
        GROUP BY a.account_id
    )
    MERGE dbo.account_cache AS tgt
    USING totals AS src
        ON tgt.account_id = src.account_id
    WHEN MATCHED THEN
        UPDATE SET tgt.balance = src.new_balance
    WHEN NOT MATCHED THEN
        INSERT (id, account_id, balance)
        VALUES ((SELECT ISNULL(MAX(id),0)+1 FROM dbo.account_cache), src.account_id, src.new_balance);
END;
GO


/* ------------------------------------------------------------
   LOGGING TRIGGERS (Requirement: log any table change;
   if record is new -> old_value = 'NEW') :contentReference[oaicite:9]{index=9}

   We log:
   - INSERT: field='*', old_value='NEW'
   - DELETE: field='*', old_value='DELETED'
   - UPDATE: one row per changed column, old_value from deleted
   ------------------------------------------------------------ */

-- Cities
CREATE OR ALTER TRIGGER dbo.trg_log_cities
ON dbo.cities
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'cities','*','NEW', i.id
    FROM inserted i LEFT JOIN deleted d ON d.id = i.id
    WHERE d.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'cities','*','DELETED', d.id
    FROM deleted d LEFT JOIN inserted i ON i.id = d.id
    WHERE i.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'cities','city_name', CONVERT(NVARCHAR(MAX), d.city_name), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.city_name,'') <> ISNULL(d.city_name,'');
END;
GO

-- Client
CREATE OR ALTER TRIGGER dbo.trg_log_client
ON dbo.client
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'client','*','NEW', i.id
    FROM inserted i LEFT JOIN deleted d ON d.id = i.id
    WHERE d.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'client','*','DELETED', d.id
    FROM deleted d LEFT JOIN inserted i ON i.id = d.id
    WHERE i.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'client','name', CONVERT(NVARCHAR(MAX), d.name), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.name,'') <> ISNULL(d.name,'');

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'client','surname', CONVERT(NVARCHAR(MAX), d.surname), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.surname,'') <> ISNULL(d.surname,'');

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'client','phone', CONVERT(NVARCHAR(MAX), d.phone), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.phone,'') <> ISNULL(d.phone,'');

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'client','city_id', CONVERT(NVARCHAR(MAX), d.city_id), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.city_id,-1) <> ISNULL(d.city_id,-1);

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'client','address', CONVERT(NVARCHAR(MAX), d.address), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.address,'') <> ISNULL(d.address,'');
END;
GO

-- Account
CREATE OR ALTER TRIGGER dbo.trg_log_account
ON dbo.account
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account','*','NEW', i.id
    FROM inserted i LEFT JOIN deleted d ON d.id = i.id
    WHERE d.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account','*','DELETED', d.id
    FROM deleted d LEFT JOIN inserted i ON i.id = d.id
    WHERE i.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account','client_id', CONVERT(NVARCHAR(MAX), d.client_id), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.client_id,-1) <> ISNULL(d.client_id,-1);

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account','account_name', CONVERT(NVARCHAR(MAX), d.account_name), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.account_name,'') <> ISNULL(d.account_name,'');

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account','creating_date', CONVERT(NVARCHAR(MAX), d.creating_date,120), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(CONVERT(DATETIME2(0), i.creating_date),'19000101')
        <> ISNULL(CONVERT(DATETIME2(0), d.creating_date),'19000101');

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account','IBAN', CONVERT(NVARCHAR(MAX), d.IBAN), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.IBAN,'') <> ISNULL(d.IBAN,'');
END;
GO

-- Account_cache
CREATE OR ALTER TRIGGER dbo.trg_log_account_cache
ON dbo.account_cache
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_cache','*','NEW', i.id
    FROM inserted i LEFT JOIN deleted d ON d.id = i.id
    WHERE d.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_cache','*','DELETED', d.id
    FROM deleted d LEFT JOIN inserted i ON i.id = d.id
    WHERE i.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_cache','account_id', CONVERT(NVARCHAR(MAX), d.account_id), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.account_id,-1) <> ISNULL(d.account_id,-1);

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_cache','balance', CONVERT(NVARCHAR(MAX), d.balance), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.balance,0) <> ISNULL(d.balance,0);
END;
GO

-- Account_detail
CREATE OR ALTER TRIGGER dbo.trg_log_account_detail
ON dbo.account_detail
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_detail','*','NEW', i.id
    FROM inserted i LEFT JOIN deleted d ON d.id = i.id
    WHERE d.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_detail','*','DELETED', d.id
    FROM deleted d LEFT JOIN inserted i ON i.id = d.id
    WHERE i.id IS NULL;

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_detail','account_id', CONVERT(NVARCHAR(MAX), d.account_id), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.account_id,-1) <> ISNULL(d.account_id,-1);

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_detail','creating_date', CONVERT(NVARCHAR(MAX), d.creating_date,120), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(CONVERT(DATETIME2(0), i.creating_date),'19000101')
        <> ISNULL(CONVERT(DATETIME2(0), d.creating_date),'19000101');

    INSERT INTO dbo.[log]([table], field, old_value, record_id)
    SELECT 'account_detail','value', CONVERT(NVARCHAR(MAX), d.value), d.id
    FROM deleted d JOIN inserted i ON i.id = d.id
    WHERE ISNULL(i.value,0) <> ISNULL(d.value,0);
END;
GO


/* ------------------------------------------------------------
   Function: Get_by_cities(@city_id) (Table Valued)
   Requirement: return name, surname, total balance for clients in city :contentReference[oaicite:10]{index=10}
   ------------------------------------------------------------ */
CREATE OR ALTER FUNCTION dbo.Get_by_cities (@city_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        c.name,
        c.surname,
        CAST(ISNULL(SUM(ac.balance), 0) AS DECIMAL(18,2)) AS total_balance
    FROM dbo.client c
    LEFT JOIN dbo.account a ON a.client_id = c.id
    LEFT JOIN dbo.account_cache ac ON ac.account_id = a.id
    WHERE c.city_id = @city_id
    GROUP BY c.name, c.surname
);
GO

/* ------------------------------------------------------------
   Test: City 14 = Siauliai (as PDF example) :contentReference[oaicite:11]{index=11}
   ------------------------------------------------------------ */
IF NOT EXISTS (SELECT 1 FROM dbo.cities WHERE id = 14)
BEGIN
    INSERT INTO dbo.cities (id, city_name)
    VALUES (14, N'Siauliai');
END;
GO

SELECT * FROM dbo.Get_by_cities(14);
GO


