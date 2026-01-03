use Bank_Information_System;
Go

-- Insert  cities
INSERT INTO cities (id, city_name) VALUES
(1, 'Vilnius'),
(2, 'Kaunas'),
(3, 'Klaipėda'),
(4, 'Šiauliai'),
(5, 'Panevėžys');

-- Insert clients 
INSERT INTO client (id, name, surname, phone, city_id, address) VALUES
(1, 'Jonas',   'Petrauskas',    '+37012345678', 1, 'Gedimino pr. 1'),
(2, 'Aistė',   'Kazlauskaitė',  '+37012345677', 2, 'Laisvės al. 10'),
(3, 'Mantas',  'Jankauskas',    '+37012345676', 3, 'Taikos pr. 25'),
(4, 'Rūta',    'Vaitkevičienė', '+37012345675', 4, 'Vilniaus g. 7'),
(5, 'Tomas',   'Brazinskas',    '+37012345674', 5, 'Respublikos g. 12');

-- Insert accounts
INSERT INTO account (id, client_id, account_name, IBAN) VALUES
(1, 1, 'Personal Account', 'LT121000011101001000'),
(2, 1, 'Savings Account',  'LT121000011101001001'),
(3, 2, 'Salary Account',   'LT121000011101001002'),
(4, 3, 'Business Account', 'LT121000011101001003'),
(5, 4, 'Personal Account', 'LT121000011101001004'),
(6, 5, 'Savings Account',  'LT121000011101001005');

-- Insert account cache (balances)
INSERT INTO account_cache (id, account_id, balance) VALUES
(1, 1, 1500.00),
(2, 2, 3500.50),
(3, 3, 2200.00),
(4, 4, 10000.00),
(5, 5, 800.00),
(6, 6, 1200.00);
Go


-- View: Customer_data
CREATE VIEW Customer_data AS
SELECT
    c.id        AS client_id,
    c.name,
    c.surname,
    c.phone,
    c.address,
    ci.city_name
FROM client c
JOIN cities ci ON c.city_id = ci.id;
Go

-- View: Client_accounts
CREATE VIEW Client_accounts AS
SELECT
    c.id        AS client_id,
    c.name,
    c.surname,
    a.id        AS account_id,
    a.account_name,
    a.IBAN,
    a.creating_date
FROM client c
JOIN account a ON c.id = a.client_id;
Go

SELECT * FROM Customer_data;
SELECT * FROM Client_accounts;
