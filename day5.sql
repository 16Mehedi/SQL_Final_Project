/* ============================================================
   TASK 4e: Triggers (recalc + logging)
   ============================================================ */
USE Bank_Information_System;
GO

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


/* ============================================================
   TASK 4f: Get_by_cities + example city 14
   ============================================================ */

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

IF NOT EXISTS (SELECT 1 FROM dbo.cities WHERE id = 14)
BEGIN
    INSERT INTO dbo.cities (id, city_name)
    VALUES (14, N'Siauliai');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.client WHERE id = 14)
BEGIN
    INSERT INTO dbo.client (id, name, surname, phone, city_id, address)
    VALUES (14, N'Thomas', N'Abc', N'+37000000014', 14, N'Siauliai address');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.account WHERE id = 14)
BEGIN
    INSERT INTO dbo.account (id, client_id, account_name, IBAN)
    VALUES (14, 14, N'Personal Account', dbo.GenerateIBAN(14));
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.account_cache WHERE account_id = 14)
BEGIN
    INSERT INTO dbo.account_cache (id, account_id, balance)
    VALUES ((SELECT ISNULL(MAX(id),0)+1 FROM dbo.account_cache), 14, 126.00);
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.client WHERE id = 15)
BEGIN
    INSERT INTO dbo.client (id, name, surname, phone, city_id, address)
    VALUES (15, N'Angel', N'BGs', N'+37000000015', 14, N'Siauliai address 2');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.account WHERE id = 15)
BEGIN
    INSERT INTO dbo.account (id, client_id, account_name, IBAN)
    VALUES (15, 15, N'Personal Account', dbo.GenerateIBAN(15));
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.account_cache WHERE account_id = 15)
BEGIN
    INSERT INTO dbo.account_cache (id, account_id, balance)
    VALUES ((SELECT ISNULL(MAX(id),0)+1 FROM dbo.account_cache), 15, 254.00);
END;
GO


SELECT * FROM dbo.Get_by_cities(14);
GO
