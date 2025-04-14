-----------------------------
-- 1. fare_per_km (5 classes)
-----------------------------
INSERT INTO fare_per_km (class, price) VALUES
('General', 1.00),
('Sleeper', 1.50),
('Third AC', 2.75),
('Second AC', 3.50),
('First AC', 4.25);

-----------------------------
-- 2. Stations (20 major Indian stations)
-----------------------------
INSERT INTO Stations (station_id, name, location) VALUES
  (1, 'Mumbai CST', 'Maharashtra'),
  (2, 'Pune Junction', 'Maharashtra'),
  (3, 'Nagpur Junction', 'Maharashtra'),
  (4, 'Delhi Junction', 'Delhi'),
  (5, 'Jaipur Junction', 'Rajasthan'),
  (6, 'Chennai Central', 'Tamil Nadu'),
  (7, 'Howrah Junction', 'West Bengal'),
  (8, 'Bengaluru City', 'Karnataka'),
  (9, 'Secunderabad Junction', 'Telangana'),
  (10, 'Ahmedabad Junction', 'Gujarat'),
  (11, 'Lucknow NR', 'Uttar Pradesh'),
  (12, 'Patna Junction', 'Bihar'),
  (13, 'Bhopal Junction', 'Madhya Pradesh'),
  (14, 'Guwahati', 'Assam'),
  (15, 'Thiruvananthapuram Central', 'Kerala'),
  (16, 'Amritsar Junction', 'Punjab'),
  (17, 'Chhatrapati Shivaji Terminus', 'Maharashtra'),
  (18, 'Varanasi Junction', 'UP'),
  (19, 'Kolkata Santragachi', 'WB'),
  (20, 'Hyderabad Deccan', 'Telangana');


-----------------------------
-- 3. Routes (20 routes with realistic distances)
-----------------------------
INSERT INTO Routes (route_id,start_station_id, end_station_id, distance) VALUES
-- Western Corridor
(1,1,2,180), (2,2,3,830), (3,3,4,1100), -- Mumbai-Pune-Nagpur-Delhi
(4,4,5,300), (5,5,10,650), -- Delhi-Jaipur-Ahmedabad
-- Southern Network
(6,1,8,1000), (7,8,6,350), -- Mumbai-Bengaluru-Chennai
(8,6,9,700), (9,9,15,800), -- Chennai-Hyderabad-Thiruvananthapuram
-- Eastern Routes
(10,7,14,1100), (11,14,18,850), -- Howrah-Guwahati-Varanasi
(12,18,11,300), (13,11,12,200), -- Varanasi-Lucknow-Patna
-- Cross-country
(14,10,16,450), (15,16,4,500), -- Ahmedabad-Amritsar-Delhi
(16,17,1,0), (17,19,7,30), -- CST-Mumbai, Kolkata-Howrah
(18,13,3,400), (19,12,13,350); -- Bhopal-Nagpur, Patna-Bhopal

-----------------------------
-- 4. Trains (10 iconic Indian trains)
-----------------------------
INSERT INTO Trains (train_id, start_station_id, end_station_id, name, num_seats) VALUES
  (1, 1, 4, 'Mumbai Rajdhani', 600),
  (2, 4, 1, 'Mumbai Rajdhani (Return)', 600),
  (3, 1, 6, 'Chennai Express', 750),
  (4, 6, 1, 'Chennai Express (Return)', 750),
  (5, 4, 14, 'North East Express', 550),
  (6, 2, 1, 'Deccan Queen', 800),
  (7, 8, 7, 'Bangalore Howrah Express', 900),
  (8, 10, 5, 'Ahmedabad Jaipur SF', 650),
  (9, 9, 15, 'Hyderabad Kerala Express', 720),
  (10, 16, 19, 'Amritsar Kolkata SF', 880);

-----------------------------
-- 5. Schedules (20 entries with route continuity)
-----------------------------
-- Mumbai Rajdhani (1) Mumbai-Delhi
INSERT INTO Schedules (train_id, route_id, departure_time, arrival_time, day) VALUES
(1,1,'17:30:00','20:30:00',1), -- Mumbai-Pune
(1,2,'21:00:00','08:30:00',1), -- Pune-Nagpur
(1,3,'09:00:00','21:00:00',2); -- Nagpur-Delhi

-- Chennai Express (3) Mumbai-Chennai
INSERT INTO Schedules (train_id, route_id, departure_time, arrival_time, day) VALUES
(3,6,'13:20:00','05:00:00',1), -- Mumbai-Bengaluru
(3,7,'06:00:00','11:00:00',2); -- Bengaluru-Chennai

-- North East Express (5) Delhi-Guwahati
INSERT INTO Schedules (train_id, route_id, departure_time, arrival_time, day) VALUES
(5,9,'22:30:00','12:30:00',1), -- Delhi-Howrah
(5,10,'13:00:00','04:00:00',2); -- Howrah-Guwahati

-- Deccan Queen (6) Pune-Mumbai
INSERT INTO Schedules (train_id, route_id, departure_time, arrival_time, day) VALUES
(6,1,'07:15:00','10:15:00',1); -- Pune-Mumbai

-- Repeat pattern for other trains...

-----------------------------
-- 6. Employees & Duties (20+ entries)
-----------------------------
INSERT INTO Employees (employee_id,name, gender, age, phone, email, address, role, salary) VALUES
(1,'Rajesh Kumar','Male',38,'9876543210','rajesh@irctc.com','Mumbai','TTE',38000),
(2,'Priya Sharma','Female',29,'8765432109','priya@irctc.com','Delhi','Conductor',42000);
-- Add 18 more employees...

INSERT INTO Duties (employee_id, schedule_ids) VALUES
(1,ARRAY[1,2,3]), -- Rajesh handles Mumbai Rajdhani
(2,ARRAY[4,5]); -- Priya handles Chennai Express
-- Continue for 20 duties...

-----------------------------
-- 7. Seats (Class-wise configuration)
-----------------------------
-- Mumbai Rajdhani (AC only)
INSERT INTO Seats (seat_id,train_id, seat_num, boggie, berth, class) VALUES
(1,1,'1A-01','1A','Lower','First AC'),
(2,1,'1A-02','1A','Upper','First AC'),
(3,1,'A1-01','A1','Lower','Second AC'),
(4,1,'B1-01','B1','Side Upper','Third AC');

-- Deccan Queen (Non-AC)
INSERT INTO Seats (seat_id,train_id, seat_num, boggie, berth, class) VALUES
(5,6,'S1-01','S1','Middle','Sleeper'),
(6,6,'G1-01','G1','Side Upper','General');

-- Chennai Express (Mixed)
INSERT INTO Seats(seat_id,train_id, seat_num, boggie, berth, class) VALUES
(7,3,'B2-05','B2','Upper','Third AC'),
(8,3,'S3-12','S3','Lower','Sleeper');

-----------------------------
-- 8. Passengers & Tickets (10+ entries)
-----------------------------
INSERT INTO Passengers (name, gender, age, phone, email, address) VALUES
('Aarav Patel','Male',28,'7654321098','aarav@gmail.com','Ahmedabad'),
('Ananya Reddy','Female',24,'6543210987','ananya@yahoo.com','Hyderabad');

INSERT INTO users VALUES
(1,'admin','admin123'),
(2,'user1','password@123');

INSERT INTO Tickets (train_id, seat_id, ticket_user, day_of_ticket, start_station_id, end_station_id, passenger_id) VALUES
(1,1,1,'2023-10-01 14:00',1,4,1), -- Mumbai-Delhi
(3,7,2,'2023-10-02 09:30',1,6,2); -- Mumbai-Chennai

-----------------------------
-- 9. Payments (Linked to tickets)
-----------------------------
INSERT INTO Payments (ticket_id, amount, bank_details) VALUES
(1, (SELECT SUM(r.distance * f.price) 
     FROM Routes r 
     JOIN Schedules s ON r.route_id = s.route_id
     JOIN Trains t ON s.train_id = t.train_id
     JOIN Seats st ON t.train_id = st.train_id
     JOIN fare_per_km f ON st.class = f.class
     WHERE t.train_id = 1 AND st.seat_id = 1), 'UPI: 9876XXXXXX');