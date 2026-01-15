/* ============================
   DAY 1: Database + Tables (UML)
   ============================ */

IF DB_ID('Bank_Information_System') IS NULL
    CREATE DATABASE Bank_Information_System;
GO

USE Bank_Information_System;
GO

-- Drop tables if you are re-running from scratch (optional, safe order)
IF OBJECT_ID('dbo.account_detail','U') IS NOT NULL DROP TABLE dbo.account_detail;
IF OBJECT_ID('dbo.account_cache','U')  IS NOT NULL DROP TABLE dbo.account_cache;
IF OBJECT_ID('dbo.account','U')        IS NOT NULL DROP TABLE dbo.account;
IF OBJECT_ID('dbo.client','U')         IS NOT NULL DROP TABLE dbo.client;
IF OBJECT_ID('dbo.cities','U')         IS NOT NULL DROP TABLE dbo.cities;
IF OBJECT_ID('dbo.[log]','U')          IS NOT NULL DROP TABLE dbo.[log];
GO

CREATE TABLE dbo.cities (
    id INT PRIMARY KEY,
    city_name NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.client (
    id INT PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    surname NVARCHAR(100) NOT NULL,
    phone NVARCHAR(20),
    city_id INT NOT NULL,
    address NVARCHAR(MAX),
    CONSTRAINT FK_client_city FOREIGN KEY (city_id) REFERENCES dbo.cities(id)
);
GO

CREATE TABLE dbo.account (
    id INT PRIMARY KEY,
    client_id INT NOT NULL,
    account_name NVARCHAR(100) NOT NULL,
    creating_date DATETIME NOT NULL CONSTRAINT DF_account_creating_date DEFAULT (GETDATE()),
    IBAN NVARCHAR(34) NOT NULL UNIQUE,
    CONSTRAINT FK_account_client FOREIGN KEY (client_id) REFERENCES dbo.client(id)
);
GO

CREATE TABLE dbo.account_detail (
    id INT PRIMARY KEY,
    account_id INT NOT NULL,
    creating_date DATETIME NOT NULL CONSTRAINT DF_detail_creating_date DEFAULT (GETDATE()),
    value DECIMAL(18,2) NULL,
    CONSTRAINT FK_detail_account FOREIGN KEY (account_id) REFERENCES dbo.account(id)
);
GO

CREATE TABLE dbo.account_cache (
    id INT PRIMARY KEY,
    account_id INT UNIQUE NOT NULL,
    balance DECIMAL(18,2) NOT NULL CONSTRAINT DF_cache_balance DEFAULT (0),
    CONSTRAINT FK_cache_account FOREIGN KEY (account_id) REFERENCES dbo.account(id)
);
GO

/* UML LOG TABLE (PDF):
   log(ID, table, field, old_value, timestamp, record_id)
*/
CREATE TABLE dbo.[log] (
    id INT IDENTITY(1,1) PRIMARY KEY,
    [table] NVARCHAR(100) NOT NULL,
    field NVARCHAR(100) NOT NULL,
    old_value NVARCHAR(MAX) NULL,
    [timestamp] DATETIME NOT NULL CONSTRAINT DF_log_timestamp DEFAULT (GETDATE()),
    record_id INT NOT NULL
);
GO

-- Indexes (requirement #2)
CREATE INDEX idx_account_iban ON dbo.account(IBAN);
CREATE INDEX idx_account_client_id ON dbo.account(client_id);
GO
