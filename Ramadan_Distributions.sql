CREATE DATABASE Ramadan_distributions;

CREATE TABLE training_sessions (
    session_id INT PRIMARY KEY AUTO_INCREMENT,
    session_name VARCHAR(100) NOT NULL,
    trainer_name VARCHAR(100) NOT NULL,
    session_date DATE NOT NULL
);

CREATE TABLE users_master (
    person_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    gender CHAR NOT NULL,
    address VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    age INT
);

CREATE TABLE driver(
    person_id INT PRIMARY KEY,
    assigned_vehicle VARCHAR(50) NOT NULL,
    Foreign Key (person_id) REFERENCES users_master(person_id)
);

CREATE TABLE admin(
    person_id INT PRIMARY KEY,
    warehouse_id INT,
    Foreign Key (person_id) REFERENCES users_master(person_id)
);

CREATE TABLE beneficiary(
    person_id INT PRIMARY KEY,
    family_members_count INT NOT NULL,
    last_received_date DATE,
    poverty_score INT CHECK(poverty_score BETWEEN 1 AND 10),
    Foreign Key (person_id) REFERENCES users_master(person_id)
);
CREATE TABLE volunteer(
    person_id INT PRIMARY KEY,
    years_of_experience INT,
    warehouse_id INT,
    Foreign Key (person_id) REFERENCES users_master(person_id)
);

CREATE TABLE driver_training(
    driver_id INT,
    session_id INT,
    PRIMARY KEY(driver_id, session_id),
    Foreign Key (driver_id) REFERENCES driver(person_id),
    Foreign Key (session_id) REFERENCES training_sessions(session_id)
);

CREATE TABLE Food_Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    food_type ENUM('Dry', 'Fresh', 'Cooked') NOT NULL,
    required_storage_temperature DECIMAL(5,2)
);

CREATE TABLE Warehouses (
    warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    max_capacity DECIMAL(10,2),
    current_status ENUM('Open', 'Full', 'Maintenance') DEFAULT 'Open'
);

CREATE TABLE Donations_Log (
    donation_id INT PRIMARY KEY AUTO_INCREMENT,
    donor_name VARCHAR(150) NOT NULL,
    amount_value DECIMAL(15,2) NOT NULL,
    donation_type ENUM('Cash', 'Food') NOT NULL,
    org_type ENUM('Individual', 'Company', 'NGO') NOT NULL
);

CREATE TABLE Inventory_Items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,
    expiry_date DATE NOT NULL,
    is_assigned_to_dry_box TINYINT(1) DEFAULT 0,
    warehouse_id INT NOT NULL,
    category_id INT NOT NULL,
    donation_id INT,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id),
    FOREIGN KEY (category_id) REFERENCES Food_Categories(category_id),
    FOREIGN KEY (donation_id) REFERENCES Donations_Log(donation_id)
);

ALTER TABLE admin
ADD Foreign Key (warehouse_id) REFERENCES warehouses(warehouse_id);

ALTER TABLE volunteer
ADD Foreign Key (warehouse_id) REFERENCES warehouses(warehouse_id);



DELIMITER $$

CREATE TRIGGER check_safety_training
BEFORE UPDATE ON driver
FOR EACH ROW
BEGIN
    IF NEW.assigned_vehicle IS NOT NULL THEN
        IF NOT EXISTS(
            SELECT 1
            FROM driver_training dt JOIN training_sessions ts
            ON dt.session_id = ts.session_id
            WHERE dt.driver_id = NEW.person_id
            AND ts.session_name = 'Safety First'
        )THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Driver must complete Safety First training before being assigned to a vehicle';
        END IF;
    END IF;
END$$


CREATE TRIGGER check_safety_training_insert
BEFORE INSERT ON driver
FOR EACH ROW
BEGIN
    IF NEW.assigned_vehicle IS NOT NULL THEN
        IF NOT EXISTS(
            SELECT 1
            FROM driver_training dt JOIN training_sessions ts
            ON dt.session_id = ts.session_id
            WHERE dt.driver_id = NEW.person_id
            AND ts.session_name = 'Safety First'
        )THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Driver must complete Safety First training before being assigned to a vehicle';
        END IF;
    END IF;
END$$

CREATE TRIGGER check_15day_rule
BEFORE UPDATE ON beneficiary
FOR EACH ROW
BEGIN
    IF NEW.last_received_date IS NOT NULL THEN
        IF OLD.last_received_date IS NOT NULL AND DATEDIFF(NEW.last_received_date, OLD.last_received_date) < 15 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot give a second box within 15 days to this family';
        END IF;
    END IF;
END$$

CREATE TRIGGER check_dry_box_expiry_before_insert
BEFORE INSERT ON Inventory_Items
FOR EACH ROW
BEGIN
    IF NEW.is_assigned_to_dry_box = 1 AND DATEDIFF(NEW.expiry_date, CURDATE()) <= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Near-expiry items (<= 3 days) cannot be entered as Dry Box items!';
    END IF;
END$$

CREATE TRIGGER check_dry_box_expiry_before_update
BEFORE UPDATE ON Inventory_Items
FOR EACH ROW
BEGIN
    IF NEW.is_assigned_to_dry_box = 1 AND DATEDIFF(NEW.expiry_date, CURDATE()) <= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: This item is near expiry (<= 3 days) and cannot be assigned to Dry Boxes.';
    END IF;
END$$

DELIMITER ;

USE Ramadan_distributions;

INSERT INTO Food_Categories (food_type, required_storage_temperature) VALUES 
('Dry', 25.0),
('Fresh', 4.0),
('Cooked', 65.0);

INSERT INTO Warehouses (name, location, max_capacity, current_status) VALUES 
('Zagazig Warehouse', 'Zagazig, Sharkia', 5000.00, 'Open'),
('Minya Al-Qamh Warehouse', 'Minya Al-Qamh, Sharkia', 3000.00, 'Open'),
('Abu Hammad Warehouse', 'Abu Hammad, Sharkia', 2000.00, 'Full'),
('Belbeis Warehouse', 'Belbeis, Sharkia', 4500.00, 'Maintenance'),
('Hihya Warehouse', 'Hihya, Sharkia', 1500.00, 'Open');

INSERT INTO Donations_Log (donor_name, amount_value, donation_type, org_type) VALUES 
('Al-Amal Company', 50000.00, 'Cash', 'Company'),
('Ahmed Ali', 1000.00, 'Cash', 'Individual'),
('Food Bank NGO', 0.00, 'Food', 'NGO'),
('Global Tech ', 75000.00, 'Cash', 'Company'),
('Mona Ibrahim', 500.00, 'Cash', 'Individual');

INSERT INTO Inventory_Items (name, quantity_kg, expiry_date, is_assigned_to_dry_box, warehouse_id, category_id) VALUES 
('Fresh Tomato', 100.00, DATE_ADD(CURDATE(), INTERVAL 1 DAY), 0, 1, 2),
('Fresh Milk', 50.00, DATE_ADD(CURDATE(), INTERVAL 40 HOUR), 0, 1, 2),
('Rice Bag', 500.00, '2027-01-01', 1, 1, 1),
('Fresh Chicken', 200.00, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 0, 2, 2),
('Pasta', 300.00, '2026-12-31', 1, 2, 1);

INSERT INTO training_sessions(session_name, trainer_name, session_date) VALUES
('Safety First','Omar Ahmed','2026-02-01'),
('Food Handling','Maryam Mohsen','2025-12-31'),
('Warehouse Management','Eslam Alaa','2026-03-11'),
('Emergency Response','Sayed Ali','2025-11-16'),
('Logistics Basics','Sara Ibrahim','2026-01-09');

INSERT INTO users_master(full_name, gender, address, phone, age) VALUES
('Omar Ahmed','M','Cairo','01001689135', 19),
('Maryam Mohsen','F','Sharqia','01065981532', 20),
('Hosam ElSayed','M','Mansoura','01035974561', 21),
('Zeyad Mohamed','M','Cairo','01532945326',20),
('Farah Hatem','F','Minya Al-Qamh','01232659819',20);

INSERT INTO driver (person_id) VALUES (1),(2),(3),(4),(5);

--needs data from warehouse
INSERT INTO admin(person_id, warehouse_id) VALUES
(1,2),
(2,1),
(3,4),
(4,3),
(5,5);

INSERT INTO beneficiary(person_id,family_members_count,last_received_date,poverty_score) VALUES
(1, 5, '2026-03-11', 8),
(2, 6, '2026-03-01', 7),
(3, 2, '2026-02-11', 9),
(4, 4, '2026-01-09', 6),
(5, 7, '2025-12-26', 10);

--needs data from warehouse
INSERT INTO volunteer(person_id, years_of_experience, warehouse_id) VALUES
(1,2,1),
(2,3,2),
(3,1,3),
(4,4,4),
(5,5,5);

INSERT INTO driver_training(driver_id, session_id) VALUES
(1,1),
(2,1),
(3,2),
(4,3),
(5,1);

UPDATE driver SET assigned_vehicle = 'Truck-1' WHERE person_id = 1;
UPDATE driver SET assigned_vehicle = 'Truck-2' WHERE person_id = 2;
UPDATE driver SET assigned_vehicle = 'Truck-3' WHERE person_id = 5;

--Query to find all fresh items in Zagazig Warehouse with their expiry dates
SELECT i.name, i.expiry_date, w.name AS warehouse_name
FROM Inventory_Items i
JOIN Warehouses w ON i.warehouse_id = w.warehouse_id
JOIN Food_Categories c ON i.category_id = c.category_id
WHERE c.food_type = 'Fresh' 
AND w.name = 'Zagazig Warehouse'
AND i.expiry_date <= DATE_ADD(NOW(), INTERVAL 48 HOUR);

--Query to find all drivers who have completed the 'Safety First' training
SELECT um.full_name
FROM users_master um
JOIN driver d ON um.person_id = d.person_id
WHERE d.person_id NOT IN (
    SELECT dt.driver_id 
    FROM driver_training dt
    JOIN training_sessions ts ON dt.session_id = ts.session_id
    WHERE ts.session_name = 'Safety First'
);

--Query to find all beneficiaries in Minya Al-Qamh with poverty score > 8 and last received date more than 15 days ago
SELECT um.full_name, b.poverty_score, b.last_received_date
FROM users_master um
JOIN beneficiary b ON um.person_id = b.person_id
WHERE um.address LIKE '%Minya Al-Qamh%'
AND b.poverty_score > 8
AND (b.last_received_date <= DATE_SUB(CURDATE(), INTERVAL 15 DAY) OR b.last_received_date IS NULL);

--Query to calculate total cash donations by organization type
SELECT org_type, SUM(amount_value) AS total_cash_donations
FROM Donations_Log
WHERE donation_type = 'Cash'
AND org_type IN ('Company', 'Individual')
GROUP BY org_type;