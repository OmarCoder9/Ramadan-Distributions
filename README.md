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


# Brief on our Database 

our Database has 11 table 

our users master table
this table contains the data for each person in this foundation even if he is a driver, admin and so on 
but every role has it's characteristic attributes so we created a four subclasses from it 

* **driver** which has the attribute assigned_vehicle and has the ability to take a training_sessions.
* **admin** which has the ability to manage a warehouse.
* **volunteer** which has skills and years of experince and has the ability to work in a warehouse.
* **Beneficiary** which has a family_member_count, poverty_score, and last_recived_date (The beneficary can't have to boxes within 15 days)

training_sessions table which has it's name and trainer name and it's date

warehouse table wich has the ability to store inventory items

Donations_log which contains many inventory items 
every inventory item categorized as food category

