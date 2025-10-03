 -- Context
-- India has a large population of stray and shelter animals, including dogs and cats. 
-- Animal shelters face challenges such as overcrowding, limited resources, and lack of centralized data.
--  Many animals remain unadopted due to age, breed, or behavioral issues, while some are returned due to mismatched expectations or insufficient adopter preparation.
-- This project builds a comprehensive SQL database to track and analyze pet adoption trends across 10 major cities with 25 shelters (multiple shelters per city).

-- Primary Goals:
-- •	Increase adoption rates for dogs and cats.
-- •	Reduce returns and improve adoption success.
-- •	Monitor shelter operations and capacity.
-- •	Understand adopter behavior and preferences.
-- •	Support predictive insights for better planning.
-- ________________________________________

CREATE DATABASE adoption;
USE adoption;

-- City table
CREATE TABLE City (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL
);

-- Shelters table
CREATE TABLE Shelters (
    shelter_id INT PRIMARY KEY,
    city_id INT NOT NULL,
    shelter_name VARCHAR(300) NOT NULL,
    capacity INT,
    staff_count INT,
    volunteer_count INT,
    contact VARCHAR(50),
    established_date DATE,
    FOREIGN KEY (city_id) REFERENCES City(city_id)
);

--  Animals table
CREATE TABLE Animals(
animal_id INT PRIMARY KEY ,
shelter_id INT NOT NULL,
animal_type ENUM('Dog','Cat'),
breed VARCHAR(200),
age INT ,
gender ENUM('Male','Female'),
animal_desc TEXT,
source ENUM('Street','Owner Surrender','Pedigree'),
intake_date DATE,
status ENUM('Adopted', 'Available', 'Deceased', 'Fostered','Returned'),
health_status VARCHAR(100),
vaccinated ENUM('TRUE','FALSE'),
neutered ENUM('TRUE','FALSE'),
fostered ENUM('TRUE','FALSE'),
FOREIGN KEY (shelter_id) REFERENCES Shelters(shelter_id)
);


-- Adopters table
CREATE TABLE Adopters (
    adopter_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT,
    gender ENUM('Male','Female'),
    city_id INT,
    contact VARCHAR(50),
    registered_date DATE,
    FOREIGN KEY (city_id) REFERENCES City(city_id)
);

-- Adoptions table
CREATE TABLE Adoptions (
    adoption_id INT PRIMARY KEY,
    animal_id INT NOT NULL,
    adopter_id INT NOT NULL,
    adoption_date DATE,
    fee DECIMAL(10,2),
    mode ENUM('Cash','UPI','Bank Transfer','Card'),
	returned ENUM('TRUE','FALSE'),
    reason   varchar(100) default null,
    FOREIGN KEY (animal_id) REFERENCES Animals(animal_id),
    FOREIGN KEY (adopter_id) REFERENCES Adopters(adopter_id)
);






select * from adoptions;
select * from city;
select * from adopters;
select * from shelters;





























