/* ============================
   DAY 2: Insert data + Views
   ============================ */

USE Bank_Information_System;
GO

/* (DATA SEEDING)
   Not a numbered task by itself, but required to demonstrate the views (Task 3)
*/

-- Cities
INSERT INTO dbo.cities (id, city_name) VALUES
(1, N'Vilnius'),
(2, N'Kaunas'),
(3, N'Klaipėda'),
(4, N'Šiauliai'),
(5, N'Panevėžys');
GO

-- Clients
INSERT INTO dbo.client (id, name, surname, phone, city_id, address) VALUES
(1, N'Jonas',   N'Petrauskas',    N'+37012345678', 1, N'Gedimino pr. 1'),
(2, N'Aistė',   N'Kazlauskaitė',  N'+37012345677', 2, N'Laisvės al. 10'),
(3, N'Mantas',  N'Jankauskas',    N'+37012345676', 3, N'Taikos pr. 25'),
(4, N'Rūta',    N'Vaitkevičienė', N'+37012345675', 4, N'Vilniaus g. 7'),
(5, N'Tomas',   N'Brazinskas',    N'+37012345674', 5, N'Respublikos g. 12');
GO

-- Accounts
INSERT INTO dbo.account (id, client_id, account_name, IBAN) VALUES
(1, 1, N'Personal Account', N'LT121000011101001000'),
(2, 1, N'Savings Account',  N'LT121000011101001001'),
(3, 2, N'Salary Account',   N'LT121000011101001002'),
(4, 3, N'Business Account', N'LT121000011101001003'),
(5, 4, N'Personal Account', N'LT121000011101001004'),
(6, 5, N'Savings Account',  N'LT121000011101001005');
GO

-- Account cache balances (seed)
INSERT INTO dbo.account_cache (id, account_id, balance) VALUES
(1, 1, 1500.00),
(2, 2, 3500.50),
(3, 3, 2200.00),
(4, 4, 10000.00),
(5, 5, 800.00),
(6, 6, 1200.00);
GO

/* ============================================================
   TASK 3a:
   Create view Customer_data with fields:
   customer_name, surname, city_name, address, phone
   ============================================================ */
CREATE OR ALTER VIEW dbo.Customer_data AS
SELECT
    c.name       AS customer_name,
    c.surname,
    ci.city_name,
    c.address,
    c.phone
FROM dbo.client c
JOIN dbo.cities ci ON ci.id = c.city_id;
GO

/* ============================================================
   TASK 3b:
   Create view Client_accounts with fields:
   client.ID, name, surname, account_type_name, IBAN, balance
   ============================================================ */
CREATE OR ALTER VIEW dbo.Client_accounts AS
SELECT
    c.id        AS client_id,          -- (client.ID)
    c.name,
    c.surname,
    a.account_name AS account_type_name,
    a.IBAN,
    ISNULL(ac.balance, 0) AS balance
FROM dbo.client c
JOIN dbo.account a ON a.client_id = c.id
LEFT JOIN dbo.account_cache ac ON ac.account_id = a.id;
GO

-- Quick checks (evidence for report screenshots)
SELECT * FROM dbo.Customer_data;
SELECT * FROM dbo.Client_accounts;
GO
