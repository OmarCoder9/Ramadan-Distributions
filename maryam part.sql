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
