-- Create Users Table (Unchanged)
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    role VARCHAR(20) CHECK (role IN ('user', 'hospital_admin')) NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    age INT CHECK (age > 0),
    emergency_contact VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Hospitals Table (Unchanged)
CREATE TABLE Hospitals (
    hospital_id SERIAL PRIMARY KEY,
    hospital_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100),
    hospital_admin_id INT REFERENCES Users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Vaccines Table (Unchanged)
CREATE TABLE Vaccines (
    vaccine_id SERIAL PRIMARY KEY,
    vaccine_name VARCHAR(100) NOT NULL,
    vaccine_type VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vaccine_information (
    info_id SERIAL PRIMARY KEY,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE CASCADE,
    how_it_works TEXT,
    side_effects TEXT,
    precautions TEXT,
    effectiveness VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Vaccine Inventory Table (Each Vaccine has a unique entry per Hospital with inventory)
CREATE TABLE Vaccine_Inventory (
    inventory_id SERIAL PRIMARY KEY,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE CASCADE,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE CASCADE,
    stock_quantity INT CHECK (stock_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE,
    UNIQUE (hospital_id, vaccine_id) -- Ensures each vaccine is uniquely connected to each hospital
);

-- Create Doctors Table (Each Doctor is unique to a Hospital)
CREATE TABLE Doctors (
    doctor_id SERIAL PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE CASCADE,
    specialization VARCHAR(100),
    experience_years INT CHECK (experience_years >= 0),
    contact VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (doctor_name, hospital_id) -- Ensures each doctor is unique per hospital
);

-- Create Appointments Table (Booking vaccines at a specific hospital and with a specific doctor)
CREATE TABLE Appointments (
    appointment_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    doctor_id INT REFERENCES Doctors(doctor_id) ON DELETE SET NULL,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE SET NULL,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE SET NULL,
    appointment_date TIMESTAMP NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'confirmed', 'completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, doctor_id, vaccine_id, hospital_id, appointment_date) -- Ensures unique appointment
);

-- Create Vaccination History Table (Unique history for each user, tracking the vaccine, doctor, and hospital)
CREATE TABLE Vaccination_History (
    history_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE SET NULL,
    date_administered DATE,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE SET NULL,
    doctor_id INT REFERENCES Doctors(doctor_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, vaccine_id, hospital_id, doctor_id, date_administered) -- Ensures unique vaccine history per user
);

-- Create Reviews Table (Unchanged)
CREATE TABLE Reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE CASCADE,
    doctor_id INT REFERENCES Doctors(doctor_id) ON DELETE CASCADE,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Insurance Details Table (Unchanged)
CREATE TABLE Insurance_Details (
    insurance_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    insurance_provider VARCHAR(100),
    policy_number VARCHAR(100),
    coverage_amount DECIMAL(10, 2),
    expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Notifications Table (Unchanged)
CREATE TABLE Notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('sent', 'pending'))
);

-- Create Vaccine Disease Types Table (Unchanged)
CREATE TABLE Vaccine_Disease_Types (
    disease_id SERIAL PRIMARY KEY,
    disease_name VARCHAR(100) NOT NULL,
    description TEXT
);

-- Create Vaccine Disease Map Table (Many-to-Many relationship between Vaccines and Diseases)
CREATE TABLE Vaccine_Disease_Map (
    id SERIAL PRIMARY KEY,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE CASCADE,
    disease_id INT REFERENCES Vaccine_Disease_Types(disease_id) ON DELETE CASCADE
);

-- Create Cities Table (Unchanged)
CREATE TABLE Cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100)
);

-- Create Hospital City Map Table (Many-to-Many relationship between Hospitals and Cities)
CREATE TABLE Hospital_City_Map (
    id SERIAL PRIMARY KEY,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE CASCADE,
    city_id INT REFERENCES Cities(city_id) ON DELETE CASCADE
);

-- Create Sessions Table (Unchanged)
CREATE TABLE Sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Insert into Users Table
INSERT INTO Users (username, password, email, role, phone, address, age, emergency_contact) VALUES
('rahul_kumar', 'pass123', 'rahul@gmail.com', 'user', '9876543210', 'Delhi, India', 28, 'Rohan Kumar'),
('priya_sharma', 'pass456', 'priya@gmail.com', 'user', '9876543211', 'Mumbai, India', 34, 'Anil Sharma'),
('amit_singh', 'pass789', 'amit@gmail.com', 'hospital_admin', '9876543212', 'Bangalore, India', 40, 'Suman Singh'),
('neha_verma', 'pass101', 'neha@gmail.com', 'user', '9876543213', 'Chennai, India', 26, 'Rajesh Verma'),
('vikas_yadav', 'pass111', 'vikas@gmail.com', 'hospital_admin', '9876543214', 'Hyderabad, India', 38, 'Aman Yadav'),
('anita_mehra', 'pass222', 'anita@gmail.com', 'user', '9876543215', 'Kolkata, India', 45, 'Seema Mehra');

-- Insert into Hospitals Table
INSERT INTO Hospitals (hospital_name, location, phone, email, hospital_admin_id) VALUES
('Apollo Hospital', 'Delhi', '011-23212345', 'apollo.delhi@gmail.com', 3),
('Fortis Hospital', 'Mumbai', '022-26201234', 'fortis.mumbai@gmail.com', 5),
('Max Healthcare', 'Bangalore', '080-23451234', 'max.bangalore@gmail.com', 3),
('Global Hospital', 'Chennai', '044-24851234', 'global.chennai@gmail.com', 3),
('Medanta', 'Hyderabad', '040-23012345', 'medanta.hyderabad@gmail.com', 5),
('AMRI Hospital', 'Kolkata', '033-24561234', 'amri.kolkata@gmail.com', 5);

-- Insert into Vaccines Table
INSERT INTO Vaccines (vaccine_name, vaccine_type, manufacturer, description) VALUES
('Covaxin', 'COVID-19', 'Bharat Biotech', 'Indigenous COVID-19 vaccine.'),
('Covishield', 'COVID-19', 'Serum Institute of India', 'AstraZeneca COVID-19 vaccine.'),
('BCG', 'Tuberculosis', 'Serum Institute of India', 'Vaccine for tuberculosis.'),
('Polio Vaccine', 'Polio', 'Indian Immunologicals', 'Polio vaccination for children.'),
('Rabies Vaccine', 'Rabies', 'Zydus Cadila', 'Prevention of rabies post-exposure.'),
('Hepatitis B Vaccine', 'Hepatitis B', 'Biological E', 'Prevention of Hepatitis B.');

INSERT INTO vaccine_information (vaccine_id, how_it_works, side_effects, precautions, effectiveness) VALUES
(1, 'Covaxin is an inactivated virus vaccine that triggers an immune response.', 'Fever, injection site pain, fatigue.', 'Pregnant women should consult a doctor before vaccination.', 'Effective against COVID-19 variants.'),
(2, 'Covishield works by using a harmless virus to deliver important instructions to our cells.', 'Headache, fatigue, fever.', 'Not recommended for individuals with severe allergies to vaccine components.', 'Approximately 70% effective.'),
(3, 'BCG vaccine helps the immune system fight tuberculosis bacteria.', 'Mild fever, redness at the injection site.', 'Not for individuals with compromised immune systems.', 'Up to 80% effective in preventing severe forms of TB.'),
(4, 'The Polio vaccine helps the body develop immunity against the poliovirus.', 'Mild fever, irritability.', 'Essential for all children as per immunization schedule.', 'Effective in reducing polio incidence significantly.'),
(5, 'Rabies vaccine stimulates the body to produce antibodies against the rabies virus.', 'Injection site soreness, mild fever.', 'Immediate vaccination after potential exposure is crucial.', 'Very effective when administered timely.'),
(6, 'Hepatitis B vaccine helps the body build immunity against Hepatitis B virus.', 'Fatigue, mild fever, soreness at the injection site.', 'Consult with a doctor if allergic to any vaccine components.', 'Over 90% effective in preventing Hepatitis B infection.');


-- Insert into Vaccine Inventory Table
INSERT INTO Vaccine_Inventory (hospital_id, vaccine_id, stock_quantity, expiry_date) VALUES
(1, 1, 100, '2025-01-01'),
(1, 2, 200, '2025-06-01'),
(2, 1, 150, '2024-12-31'),
(3, 3, 300, '2026-01-15'),
(4, 4, 250, '2025-08-10'),
(5, 5, 80, '2025-10-01'),
(6, 6, 500, '2025-09-20');

-- Insert into Doctors Table
INSERT INTO Doctors (doctor_name, hospital_id, specialization, experience_years, contact) VALUES
('Dr. Suresh Kumar', 1, 'General Medicine', 15, '011-23212346'),
('Dr. Meera Shah', 2, 'Pediatrics', 12, '022-26201235'),
('Dr. Arjun Singh', 3, 'Pulmonology', 10, '080-23451235'),
('Dr. Kavita Das', 4, 'Immunology', 8, '044-24851235'),
('Dr. Rakesh Patel', 5, 'General Medicine', 20, '040-23012346'),
('Dr. Priya Nair', 6, 'Gastroenterology', 7, '033-24561235');

-- Insert into Appointments Table
INSERT INTO Appointments (user_id, doctor_id, vaccine_id, hospital_id, appointment_date, status) VALUES
(1, 1, 1, 1, '2024-09-30 10:00:00', 'confirmed'),
(2, 2, 2, 2, '2024-09-30 11:00:00', 'confirmed'),
(4, 3, 3, 3, '2024-10-01 09:00:00', 'pending'),
(5, 4, 4, 4, '2024-10-01 12:00:00', 'completed'),
(6, 5, 5, 5, '2024-10-02 08:30:00', 'confirmed'),
(3, 6, 6, 6, '2024-10-02 09:30:00', 'pending');

-- Insert into Vaccination History Table
INSERT INTO Vaccination_History (user_id, vaccine_id, date_administered, hospital_id, doctor_id) VALUES
(1, 1, '2023-05-12', 1, 1),
(2, 2, '2023-06-15', 2, 2),
(3, 3, '2023-07-20', 3, 3),
(4, 4, '2023-08-10', 4, 4),
(5, 5, '2023-09-18', 5, 5),
(6, 6, '2023-10-22', 6, 6);

-- Insert into Reviews Table
INSERT INTO Reviews (user_id, hospital_id, doctor_id, rating, review_text) VALUES
(1, 1, 1, 5, 'Great experience with Dr. Suresh.'),
(2, 2, 2, 4, 'Dr. Meera was very helpful.'),
(3, 3, 3, 5, 'Dr. Arjun provided excellent care.'),
(4, 4, 4, 3, 'Average experience, could be better.'),
(5, 5, 5, 4, 'Dr. Rakesh is very experienced.'),
(6, 6, 6, 5, 'Very good service at AMRI.');

-- Insert into Insurance Details Table
INSERT INTO Insurance_Details (user_id, insurance_provider, policy_number, coverage_amount, expiry_date) VALUES
(1, 'LIC Health Plus', 'LIC123456', 100000.00, '2025-12-31'),
(2, 'New India Assurance', 'NIA123789', 200000.00, '2026-01-15'),
(3, 'HDFC ERGO', 'HDFC456789', 150000.00, '2025-11-20'),
(4, 'Star Health Insurance', 'STAR987654', 120000.00, '2025-09-10'),
(5, 'ICICI Lombard', 'ICICI654321', 180000.00, '2026-02-18'),
(6, 'Oriental Insurance', 'ORI321654', 170000.00, '2025-10-15');

-- Insert into Notifications Table
INSERT INTO Notifications (user_id, message, status) VALUES
(1, 'Your appointment with Dr. Suresh is confirmed.', 'sent'),
(2, 'Your appointment with Dr. Meera is confirmed.', 'sent'),
(4, 'Your appointment with Dr. Arjun is pending.', 'pending'),
(5, 'Your appointment with Dr. Kavita is completed.', 'sent'),
(6, 'Your appointment with Dr. Priya is confirmed.', 'sent'),
(3, 'Your appointment with Dr. Priya is pending.', 'pending');

-- Insert into Vaccine Disease Types Table
INSERT INTO Vaccine_Disease_Types (disease_name, description) VALUES
('COVID-19', 'Coronavirus Disease 2019'),
('Tuberculosis', 'Infectious bacterial disease'),
('Polio', 'Poliomyelitis caused by the poliovirus'),
('Rabies', 'Deadly viral disease'),
('Hepatitis B', 'Liver infection caused by the hepatitis B virus'),
('Influenza', 'Flu caused by influenza virus');

-- Insert into Vaccine Disease Map Table
INSERT INTO Vaccine_Disease_Map (vaccine_id, disease_id) VALUES
(1, 1), -- Covaxin -> COVID-19
(2, 1), -- Covishield -> COVID-19
(3, 2), -- BCG -> Tuberculosis
(4, 3), -- Polio Vaccine -> Polio
(5, 4), -- Rabies Vaccine -> Rabies
(6, 5); -- Hepatitis B Vaccine -> Hepatitis B

-- Insert into Cities Table
INSERT INTO Cities (city_name, state) VALUES
('Delhi', 'Delhi'),
('Mumbai', 'Maharashtra'),
('Bangalore', 'Karnataka'),
('Chennai', 'Tamil Nadu'),
('Hyderabad', 'Telangana'),
('Kolkata', 'West Bengal');

-- Insert into Hospital City Map Table
INSERT INTO Hospital_City_Map (hospital_id, city_id) VALUES
(1, 1), -- Apollo Hospital -> Delhi
(2, 2), -- Fortis Hospital -> Mumbai
(3, 3), -- Max Healthcare -> Bangalore
(4, 4), -- Global Hospital -> Chennai
(5, 5), -- Medanta -> Hyderabad
(6, 6); -- AMRI Hospital -> Kolkata

-- Insert into Sessions Table
INSERT INTO Sessions (user_id, token, expires_at) VALUES
(1, 'token123', '2024-09-30 12:00:00'),
(2, 'token456', '2024-09-30 12:00:00'),
(3, 'token789', '2024-09-30 12:00:00'),
(4, 'token101', '2024-10-01 12:00:00'),
(5, 'token111', '2024-10-01 12:00:00'),
(6, 'token222', '2024-10-01 12:00:00');

SELECT * FROM pg_user;
CREATE USER madhav WITH PASSWORD 'madhav';
GRANT ALL PRIVILEGES ON DATABASE vaccine TO madhav;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE users TO madhav;
GRANT USAGE, SELECT ON SEQUENCE users_user_id_seq TO madhav;
GRANT INSERT, SELECT, UPDATE ON Users TO madhav;
GRANT SELECT ON TABLE vaccines TO madhav;
GRANT SELECT ON TABLE hospitals TO madhav;
GRANT SELECT ON TABLE vaccine_inventory TO madhav;
GRANT INSERT, UPDATE, DELETE ON TABLE vaccine_inventory TO madhav;
GRANT SELECT ON TABLE doctors TO madhav;
GRANT INSERT, UPDATE, DELETE ON TABLE doctors TO madhav;
GRANT SELECT ON TABLE appointments TO madhav;
GRANT INSERT, UPDATE, DELETE ON TABLE appointments TO madhav;
GRANT SELECT ON TABLE vaccination_history TO madhav;
GRANT INSERT, UPDATE, DELETE ON TABLE vaccination_history TO madhav;
GRANT USAGE, SELECT ON SEQUENCE appointments_appointment_id_seq TO madhav;
GRANT USAGE, SELECT ON SEQUENCE vaccination_history_history_id_seq TO madhav;
GRANT UPDATE ON SEQUENCE vaccination_history_history_id_seq TO madhav;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Notifications TO madhav;
GRANT USAGE, SELECT ON SEQUENCE notifications_notification_id_seq TO madhav;
GRANT UPDATE ON SEQUENCE notifications_notification_id_seq TO madhav;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Reviews TO madhav;
GRANT USAGE, SELECT ON SEQUENCE reviews_review_id_seq TO madhav;
GRANT INSERT ON Reviews TO madhav;
GRANT SELECT ON vaccine_information TO madhav;
GRANT INSERT, UPDATE, DELETE ON vaccine_information TO madhav;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE insurance_details TO madhav;
GRANT USAGE, SELECT ON SEQUENCE insurance_details_insurance_id_seq TO madhav;




SELECT * FROM Vaccine_Inventory WHERE hospital_id = 1;
SELECT * FROM Hospitals WHERE hospital_admin_id = 1;
select * from hospitals;
select * from Users;
select * from Insurance_Details;
SELECT * FROM Users WHERE role = 'hospital_admin';
UPDATE Hospitals
SET hospital_admin_id = 1
WHERE hospital_name = 'Apollo Hospital' AND location = 'Delhi';


ALTER TABLE Appointments
ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Reviews ADD COLUMN appointment_id INT REFERENCES Appointments(appointment_id) ON DELETE CASCADE;
ALTER TABLE Users ADD COLUMN hospital_admin_id INT REFERENCES Hospitals(hospital_id) ON DELETE SET NULL;
ALTER TABLE Vaccine_Inventory
ADD COLUMN price DECIMAL(10, 2) CHECK (price >= 0);

ALTER TABLE Users DROP COLUMN IF EXISTS hospital_id; 
ALTER TABLE Users DROP COLUMN IF EXISTS hospital_admin_id;
ALTER TABLE Hospitals DROP COLUMN IF EXISTS hospital_admin_id; -- Remove the column if it exists
ALTER TABLE Hospitals ADD COLUMN hospital_admin_id INT REFERENCES Users(user_id) ON DELETE SET NULL; -- Add hospital_admin_id to Hospitals table
ALTER TABLE Users
  ALTER COLUMN role TYPE VARCHAR(20),
  ADD CONSTRAINT role_check CHECK (role IN ('user', 'hospital_admin', 'admin'));
ALTER TABLE Users
  DROP CONSTRAINT IF EXISTS users_role_check, -- Drop the old constraint
  ADD CONSTRAINT users_role_check CHECK (role IN ('user', 'hospital_admin', 'admin')); -- Add the new constraint
ALTER TABLE Users ADD COLUMN hospital_admin_id INT;
-- Modify Vaccines Table to include categories
ALTER TABLE Vaccines
ADD COLUMN category VARCHAR(50) NOT NULL DEFAULT 'Adult';
ALTER TABLE Vaccine_Inventory
ADD COLUMN notes TEXT;



INSERT INTO Users (username, password, email, role, phone)
VALUES ('madhavendra', 'madhav', 'adminhu@example.com', 'admin', '7999860730');

INSERT INTO Users (username, password, email, role, phone)
VALUES ('ma', 'ma', 'mad@example.com', 'hospital_admin', '7999860730');

select * from Hospitals;
select * from Users;



SELECT hospital_id, hospital_name, hospital_admin_id
FROM Hospitals
WHERE hospital_admin_id = (SELECT user_id FROM Users WHERE role = 'hospital_admin');

select * from Users;
select * from Hospitals;
SELECT * FROM Hospitals WHERE hospital_admin_id IS NULL;


-- Insert into Vaccines Table
INSERT INTO Vaccines (vaccine_name, vaccine_type, manufacturer, description) VALUES
('HPV Vaccine', 'Human Papillomavirus', 'Merck', 'Prevents HPV infections.'),
('MMR Vaccine', 'Measles, Mumps, Rubella', 'GlaxoSmithKline', 'Prevention of measles, mumps, and rubella.'),
('Influenza Vaccine', 'Influenza', 'Sanofi', 'Seasonal flu prevention.'),
('Tetanus Vaccine', 'Tetanus', 'Sanofi', 'Prevention of tetanus infection.'),
('Diphtheria Vaccine', 'Diphtheria', 'Pfizer', 'Prevention of diphtheria infection.'),
('Varicella Vaccine', 'Chickenpox', 'Merck', 'Prevention of chickenpox.'),
('Pneumococcal Vaccine', 'Pneumonia', 'Pfizer', 'Prevents pneumococcal diseases.'),
('Zoster Vaccine', 'Shingles', 'GlaxoSmithKline', 'Prevention of shingles in older adults.'),
('Meningococcal Vaccine', 'Meningitis', 'Pfizer', 'Prevention of meningitis.'),
('Typhoid Vaccine', 'Typhoid', 'Sanofi', 'Prevention of typhoid fever.'),
('Rotavirus Vaccine', 'Rotavirus', 'Merck', 'Prevents rotavirus infections in infants.'),
('Yellow Fever Vaccine', 'Yellow Fever', 'Sanofi', 'Prevents yellow fever.');

-- Insert into vaccine_information Table
INSERT INTO vaccine_information (vaccine_id, how_it_works, side_effects, precautions, effectiveness) VALUES
(7, 'Prevents infection from human papillomavirus.', 'Injection site pain, mild fever.', 'Not recommended for pregnant women.', 'Nearly 100% effective in preventing targeted HPV strains.'),
(8, 'Provides immunity against measles, mumps, and rubella.', 'Mild fever, rash.', 'Not for individuals with severe allergies to vaccine ingredients.', 'Highly effective after two doses.'),
(9, 'Stimulates immunity against the flu.', 'Soreness, mild fever.', 'Annual vaccination recommended.', 'Varies by season but up to 60% effective.'),
(10, 'Induces immunity against tetanus toxin.', 'Pain at injection site, mild fever.', 'Boosters required every 10 years.', 'Highly effective with booster doses.'),
(11, 'Induces immunity against diphtheria toxin.', 'Redness at the injection site.', 'Routine booster doses are recommended.', 'Nearly 100% effective after full course.'),
(12, 'Prevents chickenpox infection.', 'Mild rash, fever.', 'Avoid in immunocompromised individuals.', 'Over 90% effective.'),
(13, 'Protects against pneumococcal disease.', 'Fever, soreness.', 'Recommended for older adults and children.', '90% effective against severe illness.'),
(14, 'Provides immunity against shingles.', 'Redness at injection site, headache.', 'Recommended for adults over 50.', 'Over 90% effective.'),
(15, 'Protects against bacterial meningitis.', 'Pain at injection site, fever.', 'Recommended for teens and those at high risk.', '85-90% effective.'),
(16, 'Prevents typhoid fever caused by Salmonella typhi.', 'Fever, headache.', 'Booster dose required every 2 years.', '70-80% effective.'),
(17, 'Induces immunity against rotavirus.', 'Diarrhea, irritability.', 'Recommended for infants in their first year.', '85-98% effective.'),
(18, 'Prevents yellow fever infection.', 'Mild fever, soreness at injection site.', 'Required for travelers to endemic areas.', '95% effective.');


-- Insert into Vaccine Inventory Table
INSERT INTO Vaccine_Inventory (hospital_id, vaccine_id, stock_quantity, expiry_date) VALUES
(1, 7, 120, '2025-03-01'),
(2, 8, 200, '2024-12-01'),
(3, 9, 180, '2025-02-10'),
(4, 10, 250, '2025-08-01'),
(5, 11, 220, '2025-06-01'),
(6, 12, 190, '2025-07-20'),
(1, 13, 160, '2025-09-01'),
(2, 14, 150, '2025-10-20'),
(3, 15, 130, '2025-04-05'),
(4, 16, 170, '2025-05-15'),
(5, 17, 140, '2025-06-30'),
(6, 18, 100, '2025-08-12');

-- Insert into Doctors Table
INSERT INTO Doctors (doctor_name, hospital_id, specialization, experience_years, contact) VALUES
('Dr. Rahul Mehta', 1, 'Dermatology', 10, '011-23212347'),
('Dr. Sneha Kapoor', 2, 'Ophthalmology', 12, '022-26201236'),
('Dr. Arvind Kumar', 3, 'Cardiology', 18, '080-23451236'),
('Dr. Rina Gupta', 4, 'Pediatrics', 14, '044-24851236'),
('Dr. Karan Desai', 5, 'Endocrinology', 22, '040-23012347'),
('Dr. Sunita Roy', 6, 'Oncology', 11, '033-24561236');

-- Insert into Appointments Table
INSERT INTO Appointments (user_id, doctor_id, vaccine_id, hospital_id, appointment_date, status) VALUES
(1, 7, 7, 1, '2024-10-05 10:00:00', 'confirmed'),
(2, 8, 8, 2, '2024-10-05 11:30:00', 'confirmed'),
(3, 9, 9, 3, '2024-10-06 09:00:00', 'pending'),
(4, 10, 10, 4, '2024-10-06 12:00:00', 'completed'),
(5, 11, 11, 5, '2024-10-07 08:30:00', 'confirmed'),
(6, 12, 12, 6, '2024-10-07 09:30:00', 'pending');

-- Insert into Vaccination_History Table
INSERT INTO Vaccination_History (user_id, vaccine_id, date_administered, hospital_id, doctor_id) VALUES
(1, 7, '2023-01-12', 1, 7),
(2, 8, '2023-02-15', 2, 8),
(3, 9, '2023-03-20', 3, 9),
(4, 10, '2023-04-10', 4, 10),
(5, 11, '2023-05-18', 5, 11),
(6, 12, '2023-06-22', 6, 12);

-- Insert into Reviews Table
INSERT INTO Reviews (user_id, hospital_id, doctor_id, rating, review_text, appointment_id) VALUES
(1, 1, 7, 4, 'Good service by Dr. Rahul.', 1),
(2, 2, 8, 5, 'Dr. Sneha was great.', 2),
(3, 3, 9, 3, 'Dr. Arvind is excellent.', 3),
(4, 4, 10, 3, 'Decent experience with Dr. Rina.', 4),
(5, 5, 11, 5, 'Dr. Karan was very helpful.', 5),
(6, 6, 12, 4, 'Dr. Sunita provided excellent care.', 6);

-- Insert into Hospitals Table
INSERT INTO Hospitals (hospital_name, location, phone, email, hospital_admin_id) VALUES
('Narayana Health', 'Delhi', '011-25362345', 'narayana.delhi@gmail.com', 3),
('Sir Ganga Ram Hospital', 'Mumbai', '022-25671234', 'ganga.mumbai@gmail.com', 5),
('Manipal Hospital', 'Bangalore', '080-26651234', 'manipal.bangalore@gmail.com', 3),
('Christian Medical College', 'Vellore', '0416-22851234', 'cmc.vellore@gmail.com', 3),
('Sunshine Hospital', 'Hyderabad', '040-25562345', 'sunshine.hyderabad@gmail.com', 5),
('Ruby Hall Clinic', 'Pune', '020-26551234', 'ruby.pune@gmail.com', 5);

-- Insert into Doctors Table
INSERT INTO Doctors (doctor_name, hospital_id, specialization, experience_years, contact) VALUES
('Dr. Rohan Khanna', 7, 'Cardiology', 18, '011-25362346'),
('Dr. Pooja Menon', 8, 'Dermatology', 12, '022-25671235'),
('Dr. Amitabh Rao', 9, 'Orthopedics', 14, '080-26651235'),
('Dr. Seema Reddy', 10, 'Neurology', 20, '0416-22851235'),
('Dr. Krishna Sharma', 11, 'Ophthalmology', 10, '040-25562346'),
('Dr. Anjali Kapoor', 12, 'Gynecology', 15, '020-26551235');

-- Insert into Vaccine_Inventory Table
INSERT INTO Vaccine_Inventory (hospital_id, vaccine_id, stock_quantity, expiry_date) VALUES
(7, 1, 120, '2025-04-10'),
(8, 2, 180, '2025-07-15'),
(9, 3, 220, '2026-02-01'),
(10, 4, 150, '2025-12-20'),
(11, 5, 90, '2025-09-10'),
(12, 6, 350, '2025-11-30');

-- Insert into Appointments Table
INSERT INTO Appointments (user_id, doctor_id, vaccine_id, hospital_id, appointment_date, status) VALUES
(1, 7, 1, 7, '2024-09-29 10:30:00', 'confirmed'),
(2, 8, 2, 8, '2024-09-29 11:30:00', 'pending'),
(3, 9, 3, 9, '2024-09-30 09:00:00', 'completed'),
(4, 10, 4, 10, '2024-09-30 10:00:00', 'confirmed'),
(5, 11, 5, 11, '2024-09-30 11:00:00', 'pending'),
(6, 12, 6, 12, '2024-10-01 08:30:00', 'confirmed');
