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

INSERT INTO Routes (start_station_id, end_station_id, distance) VALUES
(1, 2, 150.00),  
(2, 9, 550.00), 
(9, 4, 800.00), 

(4, 3, 800.00),  
(3, 2, 550.00),  
(2, 1, 150.00),  

(2, 3, 420.00),
(3, 8, 840.00), 
(8, 5, 840.00),  

(5, 9, 350.00),  
(9, 1, 840.00),
(1, 11, 430.00), 

(11, 12, 365.00), 
(12, 7, 530.00),  
(7, 14, 580.00),  

(2, 1, 150.00),  
(8, 9, 570.00),  
(9, 7, 1300.00), 

(7, 5, 640.00), 
(9, 6, 650.00),  
(6, 15, 700.00), 

(15, 4, 450.00), 
(4, 7, 1300.00), 
(7, 19, 15.00);  

-- Insert Schedules
INSERT INTO Schedules (train_id, route_id, departure_time, arrival_time, day) VALUES
(1, 1, '16:00', '20:00', 1),
(1, 2, '20:30', '06:00', 1),
(1, 3, '06:30', '16:00', 2),

(2, 4, '16:30', '06:00', 1),
(2, 5, '06:30', '14:00', 2),
(2, 6, '14:30', '18:30', 2),

(3, 1, '08:00', '12:00', 1),
(3, 7, '12:30', '22:30', 1),
(3, 8, '23:00', '04:30', 2),

(4, 9, '22:00', '03:30', 1),
(4, 10, '04:00', '14:00', 2),

(5, 11, '07:00', '14:30', 1),
(5, 12, '15:00', '21:30', 1),
(5, 13, '22:00', '08:00', 2),
(5, 14, '09:00', '18:30', 2),

(6, 6, '07:15', '11:15', 1),

(7, 15, '18:00', '08:00', 1),
(7, 16, '08:30', '22:30', 2),

(8, 17, '06:00', '16:00', 1),

(9, 18, '07:00', '14:30', 1),
(9, 19, '15:00', '23:45', 1),

(10, 20, '16:00', '22:00', 1),
(10, 21, '22:30', '12:30', 2),
(10, 22, '13:00', '13:30', 2);

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

CREATE OR REPLACE FUNCTION insert_seats(
  train_id_param INTEGER,
  total_seats INTEGER
) RETURNS VOID AS $$
DECLARE
  seats_per_class INTEGER;
  next_seat_id INTEGER;
  class_name TEXT;
  boggie_prefix TEXT;
  boggie_num INTEGER;
  seat_in_boggie INTEGER;
  berth_type TEXT;
  seat_num TEXT;
BEGIN

  seats_per_class := total_seats / 5;
  SELECT COALESCE(MAX(seat_id), 0) + 1 INTO next_seat_id FROM Seats;
  
  FOR class_index IN 1..5 LOOP

    CASE class_index
      WHEN 1 THEN class_name := 'First AC'; boggie_prefix := 'A1';
      WHEN 2 THEN class_name := 'Second AC'; boggie_prefix := 'A2';
      WHEN 3 THEN class_name := 'Third AC'; boggie_prefix := 'B';
      WHEN 4 THEN class_name := 'Sleeper'; boggie_prefix := 'S';
      WHEN 5 THEN class_name := 'General'; boggie_prefix := 'G';
    END CASE;
    
    FOR i IN 1..seats_per_class LOOP
      boggie_num := (i - 1) / 12 + 1;
      seat_in_boggie := ((i - 1) % 12) + 1;
      
      CASE (i - 1) % 6
        WHEN 0 THEN berth_type := 'Lower';
        WHEN 1 THEN berth_type := 'Middle';
        WHEN 2 THEN berth_type := 'Upper';
        WHEN 3 THEN berth_type := 'Side Lower';
        WHEN 4 THEN berth_type := 'Side Upper';
        WHEN 5 THEN berth_type := 'Side Middle';
      END CASE;
      
      IF class_index <= 2 THEN
        seat_num := boggie_prefix || '-' || LPAD(seat_in_boggie::TEXT, 2, '0');
      ELSE
        seat_num := boggie_prefix || boggie_num || '-' || LPAD(seat_in_boggie::TEXT, 2, '0');
      END IF;
      
      INSERT INTO Seats (seat_id, train_id, seat_num, boggie, berth, class)
      VALUES (next_seat_id, train_id_param, seat_num::varchar(20), 
          CASE WHEN class_index <= 2 THEN boggie_prefix 
             ELSE (boggie_prefix || boggie_num::TEXT)::varchar(20) END,
          berth_type::varchar(20), class_name::varchar(20));
      
      next_seat_id := next_seat_id + 1;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT insert_seats(1, 5);
SELECT insert_seats(2, 5);
SELECT insert_seats(3, 5);
SELECT insert_seats(4, 5);
SELECT insert_seats(5, 5);
SELECT insert_seats(6, 5);
SELECT insert_seats(7, 5);
SELECT insert_seats(8, 5);
SELECT insert_seats(9, 5);
SELECT insert_seats(10, 5);

-----------------------------
-- 8. Passengers & Tickets (10+ entries)
-----------------------------
INSERT INTO Passengers (name, gender, age, phone) VALUES
('Aarav Patel','Male',28,'7654321098'),
('Ananya Reddy','Female',24,'6543210987'),
('Vikram Singh','Male',35,'9876543211'),
('Meera Iyer','Female',42,'8765432112'),
('Raj Mehta','Male',31,'9988776655');

insert into user_roles (role_id , role_name) VALUES
(0,'user_role'),
(1,'admin_role'),
(2,'employee_role');

INSERT INTO users (user_id,username,password,role_id)VALUES
(1,'user1','user1123',0),
(2,'user2','user2123',0),
(3,'admin1','admin123',1),
(4,'employee1','employee123',2),
(5, 'user3', 'user123', 0);

-- INSERT INTO Tickets (train_id, seat_id, ticket_user, day_of_ticket, start_station_id, end_station_id, passenger_id) VALUES
-- --1 2 9 4
-- (1,1,1,'2023-10-01 14:00',1,4,1), -- Mumbai-Delhi
-- (1,3,2,'2023-10-02 09:30',1,9,2), -- Mumbai-Chennai
-- --9 1 11 12 7
-- (5,7,3,'2023-10-02 09:30',1,12,3), -- Mumbai-Chennai
-- --9 6 15 4
-- (10,5,4,'2023-10-02 09:30',9,6,4), -- Mumbai-Chennai
-- (10,6,5,'2023-10-02 09:30',6,4,5); -- Mumbai-Chennai

-----------------------------
-- 9. Payments (Linked to tickets)
-----------------------------
-- INSERT INTO Payments (ticket_id, amount, bank_details) VALUES
-- (1, (SELECT SUM(r.distance * f.price) 
--      FROM Routes r 
--      JOIN Schedules s ON r.route_id = s.route_id
--      JOIN Trains t ON s.train_id = t.train_id
--      JOIN Seats st ON t.train_id = st.train_id
--      JOIN fare_per_km f ON st.class = f.class
--      WHERE t.train_id = 1 AND st.seat_id = 1), 'UPI: 9876XXXXXX');