-- allot test cases
-- DO $$
-- DECLARE
--     allocated_seat_id INT;
--     seat_number VARCHAR;
--     class_name VARCHAR;
--     ticket_date TIMESTAMP WITHOUT TIME ZONE := '2025-04-01 10:00:00';
-- BEGIN

--     allocated_seat_id := allot('Mumbai CST', 'Nagpur Junction', 'First AC', 1, ticket_date);
--     SELECT s.seat_num, s.class
--     INTO seat_number, class_name
--     FROM seats s
--     WHERE s.seat_id = allocated_seat_id;

--     RAISE NOTICE 'Test 1: 1 to 3 - Allocated seat ID: %, Seat Number: %, Class: %',
--         allocated_seat_id, seat_number, class_name;

--     INSERT INTO tickets(train_id, seat_id, start_station_id, end_station_id, passenger_id, day_of_ticket) 
--     VALUES (1, allocated_seat_id, 1, 3, 2, ticket_date);

--     -- TEST 2
--     allocated_seat_id := allot('Nagpur Junction', 'Delhi Junction', 'First AC', 1, ticket_date);
--     SELECT s.seat_num, s.class
--     INTO seat_number, class_name
--     FROM seats s
--     WHERE s.seat_id = allocated_seat_id;

--     RAISE NOTICE 'Test 2: 3 to 5 - Allocated seat ID: %, Seat Number: %, Class: %',
--         allocated_seat_id, seat_number, class_name;

--     INSERT INTO tickets(train_id, seat_id, start_station_id, end_station_id, passenger_id, day_of_ticket) 
--     VALUES (1, allocated_seat_id, 3, 4, 1, ticket_date);

--     -- TEST 3
--     allocated_seat_id := allot('Mumbai CST', 'Delhi Junction', 'First AC', 1, ticket_date);
--     SELECT s.seat_num, s.class
--     INTO seat_number, class_name
--     FROM seats s
--     WHERE s.seat_id = allocated_seat_id;

--     RAISE NOTICE 'Test 3: 1 to 5 - Allocated seat ID: %, Seat Number: %, Class: %',
--         allocated_seat_id, seat_number, class_name;

--     INSERT INTO tickets(train_id, seat_id, start_station_id, end_station_id, passenger_id, day_of_ticket) 
--     VALUES (1, allocated_seat_id, 1, 4, 2, ticket_date);

-- END $$;

-- --tests for the get_amount (this is a very important comment)
-- DO $$ 
-- DECLARE amount FLOAT; 
-- BEGIN
--     amount := get_amount('New Delhi', 'Mumbai Central', 1, 'Sleeper');
-- 	raise notice 'amount: %', amount;
-- 	amount := get_amount('New Delhi', 'Howrah Junction', 1, 'General');
-- 	raise notice 'amount: %', amount;
-- 	amount := get_amount('New Delhi', 'Chennai Central', 1, 'First AC');
-- 	raise notice 'amount: %', amount;
-- END $$;

-- call PAY(1, 'UPI-095834952839582');

-- --test admin view
-- select * from admin_train_overview;
-- --employee_view
-- select * from employee_duties(2);
-- --user bookings
-- select * from user_bookings(2);
-- --pnr check
-- select * from pnr_status(-1);

-- -- search trains
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-15');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-15', 'AC First');
-- SELECT * FROM search_trains('Delhi Junction', 'Mumbai CST', '2023-07-16');
-- SELECT * FROM search_trains('Invalid Station', 'Delhi Junction', '2023-07-15');
-- SELECT * FROM search_trains('Mumbai CST', 'Invalid Station', '2023-07-15');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-17');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-18'); 
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-19'); 
-- SELECT * FROM search_trains('Mumbai CST', 'Howrah Junction', '2023-07-15');
-- SELECT * FROM search_trains('Pune Junction', 'Bengaluru City', '2023-07-15');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2024-01-01');
-- SELECT * FROM search_trains('Mumbai CST', 'Kolkata Santragachi', '2023-07-15');
-- SELECT * FROM search_trains('Mumbai', 'Delhi', '2023-07-15');
-- SELECT * FROM search_trains('mumbai cst', 'delhi junction', '2023-07-15');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-22'); 
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-23'); 
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-12-31'); 
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2024-01-01'); 
-- SELECT * FROM search_trains('Thiruvananthapuram Central', 'Guwahati', '2023-07-15');
-- SELECT * FROM search_trains('Jaipur Junction', 'Guwahati', '2023-07-15');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-15', 'Sleeper');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-15', 'AC First');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-15', 'AC 2 Tier');
-- SELECT * FROM search_trains('Mumbai CST', 'Delhi Junction', '2023-07-15', 'AC 3 Tier');

-- Mumbai CST Delhi Junction General 1 2025-07-01 00:00:00