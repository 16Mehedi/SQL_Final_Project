# Bank Information System – SQL Server Project

## Overview

This project implements a simplified **Bank Information System** using Microsoft SQL Server.
The solution follows the provided UML model and fulfills all assignment requirements, including:

* Database schema with normalized tables and relationships
* Indexes for performance
* Views for reporting
* Functions and stored procedures for business logic
* Triggers for automatic balance recalculation and auditing

The system supports customer management, account creation, IBAN generation, money transfers with transactions, balance caching, change logging, and reporting by city.

---

## Project Structure

* **Main Script**
  Contains the full implementation:

  * Task 1: Database and tables
  * Task 2: Indexes and relationships
  * Task 3: Views
  * Task 4: Functions, procedures, triggers
  * Sample data for testing

* **Test Script**
  Used to:

  * Verify tables, foreign keys, and indexes
  * Display view outputs
  * Test IBAN generation
  * Validate `AddClientWithAccount`
  * Demonstrate `TransferMoney` (success and error)
  * Prove trigger-based balance recalculation
  * Show logging behavior
  * Test `Get_by_cities`

---

## Features Implemented

* **Relational Schema**

  * `cities`, `client`, `account`, `account_detail`, `account_cache`, `log`
  * Primary keys, foreign keys, and constraints

* **Indexes**

  * Optimized joins on key columns (e.g., `client_id`, `city_id`, `account_id`)

* **Views**

  * `Customer_data`
  * `Client_accounts`

* **Function**

  * `GenerateIBAN` – creates valid Lithuanian IBANs (LT + 70440 + number + check digits)

* **Stored Procedures**

  * `AddClientWithAccount`
  * `TransferMoney` (with validation and transaction handling)

* **Triggers**

  * Automatic recalculation of `account_cache.balance`
  * Full auditing into `log` for INSERT, UPDATE, DELETE

* **Table-Valued Function**

  * `Get_by_cities(@city_id)` – returns customers and total balances by city

---

## How to Run

1. Open SQL Server Management Studio.
2. Execute the **Main Script** to create the database and all objects.
3. Execute the **Test Script** to:

   * Capture screenshots for each task
   * Verify that all requirements are met

---

## Example Usage

```sql
EXEC dbo.AddClientWithAccount
  @name = N'Abdul',
  @surname = N'Mojid',
  @phone = N'+37063771563',
  @city_id = 1,
  @address = N'Dubijos 1a, Siauliai',
  @account_name = N'Saving Account';
```

```sql
EXEC dbo.TransferMoney
  @FromIBAN = N'LT327044000000000010',
  @ToIBAN   = N'LT597044000000000009',
  @Amount   = 10.00;
```

```sql
SELECT * FROM dbo.Get_by_cities(14);
```

---

## Notes

* New accounts are created with a balance of `0` by design.
* Balances are updated only through `account_detail` entries.
* Triggers ensure `account_cache` always reflects the true total.
* All structural and data changes are recorded in the `log` table.

This project fully satisfies the assignment requirements and demonstrates a working banking database system with transactional safety, auditability, and reporting capabilities.
