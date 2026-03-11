CREATE DATABASE Ramadan_distributions;
USE Ramadan_distributions;
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
    assigned_vehicle VARCHAR(50),
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


DELIMITER ;

USE Ramadan_distributions;
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

USE Ramadan_distributions;

SELECT um.full_name
FROM users_master um
JOIN driver d ON um.person_id = d.person_id
WHERE d.person_id NOT IN (
    SELECT dt.driver_id 
    FROM driver_training dt
    JOIN training_sessions ts ON dt.session_id = ts.session_id
    WHERE ts.session_name = 'Safety First'
);

SELECT um.full_name, b.poverty_score, b.last_received_date
FROM users_master um
JOIN beneficiary b ON um.person_id = b.person_id
WHERE um.address LIKE '%Minya Al-Qamh%'
AND b.poverty_score > 8
AND (b.last_received_date <= DATE_SUB(CURDATE(), INTERVAL 15 DAY) OR b.last_received_date IS NULL);

