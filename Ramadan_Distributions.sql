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