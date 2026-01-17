USE Bank_Information_System;
GO

/* ============================================================
   TASK 1 — DATABASE + TABLES (UML)
   Screenshot: list of tables
   ============================================================ */
SELECT name AS table_name
FROM sys.tables
WHERE schema_id = SCHEMA_ID('dbo')
ORDER BY name;
GO


/* ============================================================
   TASK 2 — RELATIONSHIPS (FOREIGN KEYS)
   Screenshot: FK list
   ============================================================ */
SELECT
  fk.name AS FK_Name,
  OBJECT_NAME(fk.parent_object_id) AS ParentTable,
  OBJECT_NAME(fk.referenced_object_id) AS RefTable
FROM sys.foreign_keys fk
ORDER BY ParentTable, FK_Name;
GO


/* ============================================================
   TASK 2 — INDEXES
   Screenshot: indexes per table
   ============================================================ */
EXEC sp_helpindex 'dbo.account';
EXEC sp_helpindex 'dbo.client';
EXEC sp_helpindex 'dbo.account_detail';
EXEC sp_helpindex 'dbo.account_cache';
GO


/* ============================================================
   TASK 3a — VIEW: Customer_data
   Screenshot: SELECT output
   ============================================================ */
SELECT TOP 10 *
FROM dbo.Customer_data
ORDER BY customer_name, surname;
GO


/* ============================================================
   TASK 3b — VIEW: Client_accounts
   Screenshot: SELECT output
   ============================================================ */
SELECT TOP 10 *
FROM dbo.Client_accounts
ORDER BY client_id, IBAN;
GO


/* ============================================================
   TASK 4a — FUNCTION: GenerateIBAN
   Screenshot 1: function text
   Screenshot 2: sample outputs
   ============================================================ */
EXEC sp_helptext 'dbo.GenerateIBAN';
GO

SELECT
  dbo.GenerateIBAN(1)  AS iban_1,
  dbo.GenerateIBAN(2)  AS iban_2,
  dbo.GenerateIBAN(10) AS iban_10;
GO


/* ============================================================
   TASK 4b — PROCEDURE: AddClientWithAccount
   Screenshot 1: procedure text
   Screenshot 2: new client + account created
   Screenshot 3: existing client gets additional account
   ============================================================ */
EXEC sp_helptext 'dbo.AddClientWithAccount';
GO

-- Create NEW client (run once)
EXEC dbo.AddClientWithAccount
  @name = N'Abdul',
  @surname = N'Mojid',
  @phone = N'+37063771563',
  @city_id = 1,
  @address = N'Dubijos 1a, Siauliai',
  @account_name = N'Saving Account';
GO

-- Proof: client row
SELECT *
FROM dbo.client
WHERE phone = N'+37063771563';
GO

-- Proof: accounts for this client
SELECT id, client_id, account_name, creating_date, IBAN
FROM dbo.account
WHERE client_id = (SELECT id FROM dbo.client WHERE phone = N'+37063771563')
ORDER BY id;
GO

-- Proof: cache rows for this client’s accounts
SELECT *
FROM dbo.account_cache
WHERE account_id IN (
  SELECT id FROM dbo.account
  WHERE client_id = (SELECT id FROM dbo.client WHERE phone = N'+37063771563')
)
ORDER BY id;
GO

-- Existing client: add another account (run once)
EXEC dbo.AddClientWithAccount
  @name = N'Abdul',
  @surname = N'Mojid',
  @phone = N'+37063771563',
  @city_id = 1,
  @address = N'Dubijos 1a, Siauliai',
  @account_name = N'Personal Account';
GO

-- Proof: now 2+ accounts with different IBANs
SELECT id, client_id, account_name, IBAN
FROM dbo.account
WHERE client_id = (SELECT id FROM dbo.client WHERE phone = N'+37063771563')
ORDER BY id;
GO


/* ============================================================
   TASK 4c / 4d — PROCEDURE: TransferMoney
   Screenshot 1: procedure text
   Screenshot 2: successful transfer (before/after + details)
   Screenshot 3: error case (bad IBAN)
   ============================================================ */
EXEC sp_helptext 'dbo.TransferMoney';
GO

DECLARE @FromIBAN NVARCHAR(34);
DECLARE @ToIBAN   NVARCHAR(34);

SELECT TOP 1 @FromIBAN = IBAN
FROM dbo.account
ORDER BY id DESC;

SELECT TOP 1 @ToIBAN = IBAN
FROM dbo.account
WHERE IBAN <> @FromIBAN
ORDER BY id DESC;

INSERT INTO dbo.account_detail (id, account_id, value)
VALUES
(
  (SELECT ISNULL(MAX(id),0) + 1 FROM dbo.account_detail),
  (SELECT id FROM dbo.account WHERE IBAN = @FromIBAN),
  50.00
);

SELECT 'BEFORE' AS stage, a.id AS account_id, a.IBAN, ac.balance
FROM dbo.account a
JOIN dbo.account_cache ac ON ac.account_id = a.id
WHERE a.IBAN IN (@FromIBAN, @ToIBAN);

EXEC dbo.TransferMoney
  @FromIBAN = @FromIBAN,
  @ToIBAN   = @ToIBAN,
  @Amount   = 10.00;

SELECT 'AFTER' AS stage, a.id AS account_id, a.IBAN, ac.balance
FROM dbo.account a
JOIN dbo.account_cache ac ON ac.account_id = a.id
WHERE a.IBAN IN (@FromIBAN, @ToIBAN);

SELECT TOP 10 *
FROM dbo.account_detail
ORDER BY id DESC;
GO
/*4c3*/
DECLARE @ToIBAN2 NVARCHAR(34);

SELECT TOP 1 @ToIBAN2 = IBAN
FROM dbo.account
ORDER BY id;

EXEC dbo.TransferMoney
  @FromIBAN = N'LT000000000000000000000000000000',
  @ToIBAN   = @ToIBAN2,
  @Amount   = 10.00;
GO


/* ============================================================
   TASK 4d — TRIGGER: account_detail -> recalc account_cache.balance
   Screenshot 1: trigger text
   Screenshot 2: before/after balance changes after insert
   ============================================================ */
EXEC sp_helptext 'dbo.trg_account_detail_recalc_cache';
GO

DECLARE @accId INT = (SELECT TOP 1 id FROM dbo.account ORDER BY id);

SELECT @accId AS account_id,
       (SELECT balance FROM dbo.account_cache WHERE account_id = @accId) AS before_balance;

INSERT INTO dbo.account_detail (id, account_id, value)
VALUES ((SELECT ISNULL(MAX(id),0)+1 FROM dbo.account_detail), @accId, 123.45);

SELECT @accId AS account_id,
       (SELECT balance FROM dbo.account_cache WHERE account_id = @accId) AS after_balance;
GO


/* ============================================================
   TASK 4e — LOGGING: any table change written to log
   Screenshot 1: insert -> log shows NEW
   Screenshot 2: update -> log shows old value
   ============================================================ */
IF NOT EXISTS (SELECT 1 FROM dbo.cities WHERE id = 99)
BEGIN
  INSERT INTO dbo.cities (id, city_name) VALUES (99, N'TestCity');
END;
GO

SELECT TOP 10 *
FROM dbo.[log]
ORDER BY id DESC;
GO

UPDATE dbo.cities
SET city_name = N'TestCityRenamed'
WHERE id = 99;
GO

SELECT TOP 10 *
FROM dbo.[log]
ORDER BY id DESC;
GO


/* ============================================================
   TASK 4f — FUNCTION: Get_by_cities(city_id)
   Screenshot 1: function text
   Screenshot 2: results for city_id 14 (example)
   ============================================================ */
EXEC sp_helptext 'dbo.Get_by_cities';
GO

SELECT * FROM dbo.Get_by_cities(14);
GO


/* ============================================================
   EXTRA (optional): show row counts for report
   ============================================================ */
SELECT COUNT(*) AS clients FROM dbo.client;
SELECT COUNT(*) AS accounts FROM dbo.account;
SELECT COUNT(*) AS account_details FROM dbo.account_detail;
GO

