# Database Concepts: Indexing, Triggers, Backup & Recovery

Modern Databases must handle large amount of data while remaining fast, reliable and secure <br/>
Three important techniques used to achive this are **Indeing**, **Triggers** and **Backup & Recovery**. <br/>
<hr>

## 1. Database Indexing
### What is indexing?
A **Database Indexing** is a data structure that improves the speed of data retrieval operations on a certain table. <br>

without an index the databasae must search in each row in the table to find the value that you're searching for.<br>
with an index the database can locate where is the data that you're searching for much faster, it is similar to the **index of the book** you have a title and you're searching to find it, instead of searching in each page of the book you can use the index and it will tell you which page has exactly this title.<br>

We usually create index for a certain type of columns **not every column in the table**
What is the characteristics that should be in a column so we can use index in it?
* Frquantly searched
* Used in `WHERE` clauses
* Used in `JOIN` between tables

### Example
Create an index on the `email` column in the `users` table:
```sql
CREATE INDEX idx_users_email
ON users(email);
```
Now we can search using email and the retrieval of data will be much faster than before
```sql
SELECT *
FROM users
WHERE email = 'Omar@gmail.com';
```
<hr>

## 2. Triggers

### What is Trigger?

A **Trigger** is a special type of stored procedure that automatically executes when a specific event happens.

### what are this events?
* A row is inserted
* A row is updated
* A row is deleted

### Why to use Triggers?
* To enforce business rules 
* To validate data
* To automatically update related tables

### Example
This trigger prevents inserting a product with a negative price
```sql
DELIMITER $$
CREATE TRIGGER check_price
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.price < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'price cannot be negative';
    END IF;
END$$

DELIMITER ;
```
When someone try to insert an invalid data like a negative number in price column the trigger will be turned on an show an error massage that clarifies negative number is not allowed as a price.


## 3. Backup & Recovery
### What is Backup?
A **Backup** is a copy of the database that is stored separately from the orignal one

the Backups protects data from problems such as:
* Hardware Failure
* System Crashes
* Accidental Deleting
* Cyber Attacks

### What is the recovery?
The **Recovery** is a process that restores the data from the backup after one of the failures mentioned before

Together, **Backup & Recovery** ensures that data can be restored if somthing happend

<hr>

## Summary
|Concept|Purpose|
|-------|-------|
|Indexing|Improves query performance and speeds up searches|
|Triggers|Automatically execute actions when a certain event happens|
|Backup & Recovery|Protects data and allows restoration after failures|

This techniques help to ensure that databases remain **efficient**, **reliable**, **secure**.

# Ramadan Distributions Database – Brief Overview

## 1. Introduction

The **Ramadan Distributions Database** is designed to manage and organize food aid distribution during Ramadan.
It supports the coordination of **beneficiaries, volunteers, drivers, warehouses, food inventory, donations, and training sessions** to ensure fair and efficient distribution of food supplies.

The system also enforces important **business rules using database triggers** to maintain data integrity and prevent operational mistakes.

<hr/>

## 2. Main Entities

### Users Master (Superclass)

The `users_master` table acts as a **central directory for all people in the system**.

It stores general information such as:

* Full name
* Gender
* Address
* Phone number
* Age

Each user receives a unique `person_id`.

### Subclasses of Users

The system implements **specialized roles** using separate tables linked to `users_master`.

| Table         | Description                                        |
| ------------- | -------------------------------------------------- |
| `driver`      | Drivers responsible for transporting food supplies |
| `admin`       | Administrators managing warehouses                 |
| `volunteer`   | Volunteers assisting in warehouse operations       |
| `beneficiary` | Families receiving food aid                        |

Each subclass uses `person_id` as a **primary key and foreign key** referencing `users_master`.

<hr/>

## 3. Training Management

### Training Sessions

The `training_sessions` table stores information about training programs such as:

* Safety training
* Food handling
* Logistics management

Attributes include:

* `session_name`
* `trainer_name`
* `session_date`

### Driver Training

The `driver_training` table represents a **many-to-many relationship** between drivers and training sessions.

A driver can attend multiple sessions, and each session can have multiple drivers.

Primary Key:

```
(driver_id, session_id)
```

<hr/>

## 4. Warehousing System

### Warehouses

The `warehouses` table stores warehouse details including:

* Warehouse name
* Location
* Maximum capacity
* Operational status

Warehouse status is restricted using an `ENUM`:

* Open
* Full
* Maintenance

Admins and volunteers are assigned to warehouses through foreign key relationships.

<hr/>

## 5. Food Management

### Food Categories

The `food_categories` table classifies food items into three types:

* Dry
* Fresh
* Cooked

Each category also stores the **required storage temperature**.

### Inventory Items

The `inventory_items` table tracks food stored in warehouses.

Important attributes:

* Item name
* Quantity (kg)
* Expiry date
* Warehouse location
* Food category
* Donation source

Items may optionally be **assigned to dry food boxes** for distribution.

<hr/>

## 6. Donation Tracking

The `donations_log` table records all donations received by the organization.

It includes:

* Donor name
* Donation value
* Donation type (Cash or Food)
* Organization type (Individual, Company, NGO)

This allows tracking of **financial contributions and food donations**.

<hr/>

## 7. Business Rules (Triggers)

Several **database triggers enforce operational rules**.

### Driver Safety Rule

A driver **cannot be assigned a vehicle** unless they have completed the **"Safety First" training session**.

This rule is enforced on:

* Driver insertion
* Driver updates

<hr/>

### Beneficiary Distribution Rule

A beneficiary **cannot receive a second food box within 15 days** of their previous distribution.

This prevents unfair distribution of aid.

<hr/>

### Dry Box Expiry Rule

Food items that will expire within **3 days or less** cannot be assigned to **dry food boxes**.

This ensures that only safe food items are distributed.

<hr/>

# 8. Conclusion

The **Ramadan Distributions Database** provides a structured system for managing humanitarian food distribution.

It combines:

* **Relational database design**
* **Role specialization**
* **Inventory management**
* **Donation tracking**
* **Automated business rules through triggers**

This ensures **efficient operations, fair distribution, and data integrity** during large-scale food aid campaigns.
