create database Bank_Information_System;
use Bank_Information_System;

CREATE TABLE cities (
    id INT IDENTITY PRIMARY KEY,
    city_name NVARCHAR(100) NOT NULL
);

CREATE TABLE client (
    id INT IDENTITY PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    surname NVARCHAR(100) NOT NULL,
    phone NVARCHAR(20),
    city_id INT NOT NULL,
    address NVARCHAR(MAX),
    CONSTRAINT FK_client_city FOREIGN KEY (city_id)
        REFERENCES cities(id)
);

CREATE TABLE account (
    id INT IDENTITY PRIMARY KEY,
    client_id INT NOT NULL,
    account_name NVARCHAR(100) NOT NULL,
    creating_date DATETIME DEFAULT GETDATE(),
    IBAN NVARCHAR(34) NOT NULL UNIQUE,
    CONSTRAINT FK_account_client
        FOREIGN KEY (client_id) REFERENCES client(id)
);


CREATE TABLE account_detail (
    id INT IDENTITY PRIMARY KEY,
    account_id INT,
    creating_date DATETIME DEFAULT GETDATE(),
    value DECIMAL(18,2),
    CONSTRAINT FK_detail_account FOREIGN KEY (account_id)
        REFERENCES account(id)
);

CREATE TABLE account_cache (
    id INT IDENTITY PRIMARY KEY,
    account_id INT UNIQUE,
    balance DECIMAL(18,2) DEFAULT 0,
    CONSTRAINT FK_cache_account FOREIGN KEY (account_id)
        REFERENCES account(id)
);

CREATE TABLE log (
    id INT IDENTITY PRIMARY KEY,
    table_name NVARCHAR(100) NOT NULL,
    field NVARCHAR(100) NOT NULL,
    old_value NVARCHAR(MAX),
    new_value NVARCHAR(MAX),
    changed_at DATETIME DEFAULT GETDATE() NOT NULL,
    record_id INT NOT NULL
);


-- Index on IBAN
CREATE INDEX idx_account_iban
ON account(IBAN);

-- Index on foreign key client_id
CREATE INDEX idx_account_client_id
ON account(client_id);
