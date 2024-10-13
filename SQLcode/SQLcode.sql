-- Create Users Table (Unchanged)
CREATE TABLE Users
(
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
CREATE TABLE Hospitals
(
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
CREATE TABLE Vaccines
(
    vaccine_id SERIAL PRIMARY KEY,
    vaccine_name VARCHAR(100) NOT NULL,
    vaccine_type VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vaccine_information
(
    info_id SERIAL PRIMARY KEY,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE CASCADE,
    how_it_works TEXT,
    side_effects TEXT,
    precautions TEXT,
    effectiveness VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Vaccine Inventory Table (Each Vaccine has a unique entry per Hospital with inventory)
CREATE TABLE Vaccine_Inventory
(
    inventory_id SERIAL PRIMARY KEY,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE CASCADE,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE CASCADE,
    stock_quantity INT CHECK (stock_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE,
    UNIQUE (hospital_id, vaccine_id)
    -- Ensures each vaccine is uniquely connected to each hospital
);

-- Create Doctors Table (Each Doctor is unique to a Hospital)
CREATE TABLE Doctors
(
    doctor_id SERIAL PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE CASCADE,
    specialization VARCHAR(100),
    experience_years INT CHECK (experience_years >= 0),
    contact VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (doctor_name, hospital_id)
    -- Ensures each doctor is unique per hospital
);

-- Create Appointments Table (Booking vaccines at a specific hospital and with a specific doctor)
CREATE TABLE Appointments
(
    appointment_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    doctor_id INT REFERENCES Doctors(doctor_id) ON DELETE SET NULL,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE SET NULL,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE SET NULL,
    appointment_date TIMESTAMP NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'confirmed', 'completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, doctor_id, vaccine_id, hospital_id, appointment_date)
    -- Ensures unique appointment
);

-- Create Vaccination History Table (Unique history for each user, tracking the vaccine, doctor, and hospital)
CREATE TABLE Vaccination_History
(
    history_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE SET NULL,
    date_administered DATE,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE SET NULL,
    doctor_id INT REFERENCES Doctors(doctor_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, vaccine_id, hospital_id, doctor_id, date_administered)
    -- Ensures unique vaccine history per user
);

-- Create Reviews Table (Unchanged)
CREATE TABLE Reviews
(
    review_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE CASCADE,
    doctor_id INT REFERENCES Doctors(doctor_id) ON DELETE CASCADE,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Insurance Details Table (Unchanged)
CREATE TABLE Insurance_Details
(
    insurance_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    insurance_provider VARCHAR(100),
    policy_number VARCHAR(100),
    coverage_amount DECIMAL(10, 2),
    expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Notifications Table (Unchanged)
CREATE TABLE Notifications
(
    notification_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('sent', 'pending'))
);

-- Create Vaccine Disease Types Table (Unchanged)
CREATE TABLE Vaccine_Disease_Types
(
    disease_id SERIAL PRIMARY KEY,
    disease_name VARCHAR(100) NOT NULL,
    description TEXT
);

-- Create Vaccine Disease Map Table (Many-to-Many relationship between Vaccines and Diseases)
CREATE TABLE Vaccine_Disease_Map
(
    id SERIAL PRIMARY KEY,
    vaccine_id INT REFERENCES Vaccines(vaccine_id) ON DELETE CASCADE,
    disease_id INT REFERENCES Vaccine_Disease_Types(disease_id) ON DELETE CASCADE
);

-- Create Cities Table (Unchanged)
CREATE TABLE Cities
(
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100)
);

-- Create Hospital City Map Table (Many-to-Many relationship between Hospitals and Cities)
CREATE TABLE Hospital_City_Map
(
    id SERIAL PRIMARY KEY,
    hospital_id INT REFERENCES Hospitals(hospital_id) ON DELETE CASCADE,
    city_id INT REFERENCES Cities(city_id) ON DELETE CASCADE
);

-- Create Sessions Table (Unchanged)
CREATE TABLE Sessions
(
    session_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

ALTER TABLE Appointments
ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Reviews ADD COLUMN appointment_id INT REFERENCES Appointments
(appointment_id) ON
DELETE CASCADE;
ALTER TABLE Users ADD COLUMN hospital_admin_id INT REFERENCES Hospitals
(hospital_id) ON
DELETE
SET NULL;

