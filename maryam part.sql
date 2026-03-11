CREATE DATABASE Ramadan_distributions;
USE Ramadan_distributions;

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

DELIMITER $$

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
('Global Tech Corp', 75000.00, 'Cash', 'Company'),
('Mona Ibrahim', 500.00, 'Cash', 'Individual');

INSERT INTO Inventory_Items (name, quantity_kg, expiry_date, is_assigned_to_dry_box, warehouse_id, category_id) VALUES 
('Fresh Tomato', 100.00, DATE_ADD(CURDATE(), INTERVAL 1 DAY), 0, 1, 2),
('Fresh Milk', 50.00, DATE_ADD(CURDATE(), INTERVAL 40 HOUR), 0, 1, 2),
('Rice Bag', 500.00, '2027-01-01', 1, 1, 1),
('Fresh Chicken', 200.00, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 0, 2, 2),
('Pasta', 300.00, '2026-12-31', 1, 2, 1);

SELECT i.name, i.expiry_date, w.name AS warehouse_name
FROM Inventory_Items i
JOIN Warehouses w ON i.warehouse_id = w.warehouse_id
JOIN Food_Categories c ON i.category_id = c.category_id
WHERE c.food_type = 'Fresh' 
AND w.name = 'Zagazig Warehouse'
AND i.expiry_date <= DATE_ADD(NOW(), INTERVAL 48 HOUR);

SELECT org_type, SUM(amount_value) AS total_cash_donations
FROM Donations_Log
WHERE donation_type = 'Cash'
AND org_type IN ('Company', 'Individual')
GROUP BY org_type;