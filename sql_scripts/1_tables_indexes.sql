DROP TABLE IF EXISTS fare_per_km CASCADE;
DROP TABLE IF EXISTS Stations CASCADE;
DROP TABLE IF EXISTS Routes CASCADE;
DROP TABLE IF EXISTS Employees CASCADE;
DROP TABLE IF EXISTS Trains CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS password_reset_tokens CASCADE;
DROP TABLE IF EXISTS Schedules CASCADE;
DROP TABLE IF EXISTS Duties CASCADE;
DROP TABLE IF EXISTS Passengers CASCADE;
DROP TABLE IF EXISTS Seats CASCADE;
DROP TABLE IF EXISTS tickets CASCADE;
DROP TABLE IF EXISTS waiting_list CASCADE;
DROP SEQUENCE IF EXISTS shared_ticket_id;
DROP TABLE IF EXISTS Payments CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;

-- DROP INDEX IF EXISTS idx_tickets_train_date;
-- DROP INDEX IF EXISTS idx_waiting_list_train_date;
-- DROP INDEX IF EXISTS idx_schedules_train_day;
-- DROP INDEX IF EXISTS idx_seats_train_class;
-- DROP INDEX IF EXISTS idx_stations_name;
-- DROP INDEX IF EXISTS idx_routes_stations;
-- DROP INDEX IF EXISTS idx_payments_ticket;
-- DROP INDEX IF EXISTS idx_users_username;

-- DO $$
-- BEGIN
--     IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'user_role') THEN
--         REASSIGN OWNED BY user_role TO postgres;
--         DROP OWNED BY user_role;
--         DROP ROLE user_role;
--     END IF;
--     IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'employee_role') THEN
--         REASSIGN OWNED BY employee_role TO postgres;
--         DROP OWNED BY employee_role;
--         DROP ROLE employee_role;
--     END IF;
--     IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_role') THEN
--         REASSIGN OWNED BY admin_role TO postgres;
--         DROP OWNED BY admin_role;
--         DROP ROLE admin_role;
--     END IF;
-- END$$;

-- tables and sequence
create table fare_per_km(
	class varchar(20) primary key not null,
	price float
);

CREATE TABLE Stations (
    station_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

-- Routes table
CREATE TABLE Routes (
    route_id SERIAL PRIMARY KEY,
    start_station_id INTEGER NOT NULL REFERENCES Stations(station_id),
    end_station_id INTEGER NOT NULL REFERENCES Stations(station_id),
    distance DECIMAL(10, 2)
);

-- Employees table
CREATE TABLE Employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    gender VARCHAR(20),
    age INTEGER,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    role VARCHAR(50),
    salary DECIMAL(10, 2)
);

-- Trains table
CREATE TABLE Trains (
    train_id SERIAL PRIMARY KEY,
    start_station_id INTEGER NOT NULL references Stations,
    end_station_id INTEGER NOT NULL references Stations,
    name VARCHAR(100) NOT NULL,
    num_seats INTEGER NOT NULL,
    CONSTRAINT unique_train_route_name UNIQUE (start_station_id, end_station_id, name)
);

CREATE TABLE user_roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(20) NOT NULL UNIQUE,
    description TEXT
);

Create TABLE users(
    user_id INTEGER primary key,
    username varchar(20) UNIQUE,
    password varchar(255),
    role_id integer REFERENCES user_roles(role_id)
);

-- Password reset functionality
CREATE TABLE password_reset_tokens (
    user_id INTEGER PRIMARY KEY REFERENCES users(user_id),
    token VARCHAR(64) NOT NULL,
    expiry_date TIMESTAMP NOT NULL
);

-- Schedules table
CREATE TABLE Schedules (
    schedule_id SERIAL PRIMARY KEY,
    train_id INTEGER NOT NULL REFERENCES Trains(train_id),
    route_id INTEGER NOT NULL REFERENCES Routes(route_id),
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    day INT,
    CONSTRAINT unique_schedule UNIQUE(train_id, route_id, departure_time, day)
);

-- Duties table (Modified for array of schedule_id)
CREATE TABLE Duties (
    duty_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES Employees(employee_id),
    schedule_ids INTEGER[] NOT NULL, -- Array to store multiple schedule_ids
    CONSTRAINT unique_duty UNIQUE(employee_id) -- Ensures one duty entry per employee
);

-- Passengers table
CREATE TABLE Passengers (
    passenger_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    gender VARCHAR(20),
    age INTEGER,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT
);

-- Seats table
CREATE TABLE Seats (
    seat_id SERIAL PRIMARY KEY,
    train_id integer REFERENCES trains,
    seat_num VARCHAR(20) NOT NULL,
    boggie VARCHAR(20),
    berth VARCHAR(20),
    class VARCHAR(20) references fare_per_km
);

-- shared primary_key between tickets and waiting_list table
create sequence shared_ticket_id start with 1 increment by 1;

-- tickets table
CREATE TABLE tickets (
    ticket_id INT PRIMARY KEY default nextval('shared_ticket_id'),       					-- added the shared_ticket_id
    train_id INTEGER NOT NULL REFERENCES Trains(train_id),
    seat_id INTEGER NOT NULL REFERENCES Seats(seat_id),
    ticket_user integer references users,
    day_of_ticket timestamp NOT NULL,
    start_station_id INTEGER NOT NULL REFERENCES Stations(station_id),
    end_station_id INTEGER NOT NULL REFERENCES Stations(station_id),
    passenger_id INTEGER NOT NULL REFERENCES Passengers(passenger_id),
    CONSTRAINT unique_ticket UNIQUE(train_id, seat_id, day_of_ticket, passenger_id)		-- unique should also be day_of_ticket 
);

-- waiting_list table
CREATE TABLE waiting_list (
    ticket_id INT PRIMARY KEY default nextval('shared_ticket_id'),       					-- added the shared_ticket_id
    train_id INTEGER NOT NULL REFERENCES Trains(train_id),
    ticket_user integer references users,
    day_of_ticket timestamp,
    start_station_id INTEGER NOT NULL REFERENCES Stations(station_id),
    end_station_id INTEGER NOT NULL REFERENCES Stations(station_id),
    passenger_id INTEGER NOT NULL REFERENCES Passengers(passenger_id),
	class varchar(20) references fare_per_km,												-- added class preference for allot function to work
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_waiting_list UNIQUE(train_id, day_of_ticket, passenger_id)					-- removed seat_id from unique constraint as it is null 
);

-- Payments table
CREATE TABLE Payments (
    payment_id SERIAL PRIMARY KEY,
    ticket_id INTEGER NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    bank_details VARCHAR(255)
);

-- Trigger to maintain audit logs for database changes
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    record_id INTEGER NOT NULL,
    changed_by INTEGER REFERENCES users(user_id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_data JSONB,
    new_data JSONB
);

-- Add indexes for frequently queried columns
-- CREATE INDEX idx_tickets_train_date ON tickets (train_id, day_of_ticket);
-- CREATE INDEX idx_waiting_list_train_date ON waiting_list (train_id, day_of_ticket);
-- CREATE INDEX idx_schedules_train_day ON schedules (train_id, day);
-- CREATE INDEX idx_seats_train_class ON seats (train_id, class);
-- CREATE INDEX idx_stations_name ON stations (name);
-- CREATE INDEX idx_routes_stations ON routes (start_station_id, end_station_id);
-- CREATE INDEX idx_payments_ticket ON payments (ticket_id);
-- CREATE INDEX idx_users_username ON users (username);

--creating role and granting all privilages

DROP TRIGGER IF EXISTS after_ticket_cancel ON tickets;
DROP TRIGGER IF EXISTS before_ticket_insert ON tickets;
DROP TRIGGER IF EXISTS tickets_audit ON tickets;
