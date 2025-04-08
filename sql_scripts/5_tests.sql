-- allot test cases
DO $$
DECLARE
    allocated_seat_id INT;
    seat_number VARCHAR;
    class_name VARCHAR;
    ticket_date TIMESTAMP WITHOUT TIME ZONE := '2025-04-01 10:00:00';
BEGIN

    allocated_seat_id := allot('Mumbai CST', 'Nagpur Junction', 'First AC', 1, ticket_date);
    SELECT s.seat_num, s.class
    INTO seat_number, class_name
    FROM seats s
    WHERE s.seat_id = allocated_seat_id;

    RAISE NOTICE 'Test 1: 1 to 3 - Allocated seat ID: %, Seat Number: %, Class: %',
        allocated_seat_id, seat_number, class_name;

    INSERT INTO tickets(train_id, seat_id, start_station_id, end_station_id, passenger_id, day_of_ticket) 
    VALUES (1, allocated_seat_id, 1, 3, 2, ticket_date);

    -- TEST 2
    allocated_seat_id := allot('Nagpur Junction', 'Delhi Junction', 'First AC', 1, ticket_date);
    SELECT s.seat_num, s.class
    INTO seat_number, class_name
    FROM seats s
    WHERE s.seat_id = allocated_seat_id;

    RAISE NOTICE 'Test 2: 3 to 5 - Allocated seat ID: %, Seat Number: %, Class: %',
        allocated_seat_id, seat_number, class_name;

    INSERT INTO tickets(train_id, seat_id, start_station_id, end_station_id, passenger_id, day_of_ticket) 
    VALUES (1, allocated_seat_id, 3, 4, 1, ticket_date);

    -- TEST 3
    allocated_seat_id := allot('Mumbai CST', 'Delhi Junction', 'First AC', 1, ticket_date);
    SELECT s.seat_num, s.class
    INTO seat_number, class_name
    FROM seats s
    WHERE s.seat_id = allocated_seat_id;

    RAISE NOTICE 'Test 3: 1 to 5 - Allocated seat ID: %, Seat Number: %, Class: %',
        allocated_seat_id, seat_number, class_name;

    INSERT INTO tickets(train_id, seat_id, start_station_id, end_station_id, passenger_id, day_of_ticket) 
    VALUES (1, allocated_seat_id, 1, 4, 2, ticket_date);

END $$;

--tests for the get_amount (this is a very important comment)
DO $$ 
DECLARE amount FLOAT; 
BEGIN
    amount := get_amount('New Delhi', 'Mumbai Central', 1, 'Sleeper');
	raise notice 'amount: %', amount;
	amount := get_amount('New Delhi', 'Howrah Junction', 1, 'General');
	raise notice 'amount: %', amount;
	amount := get_amount('New Delhi', 'Chennai Central', 1, 'First AC');
	raise notice 'amount: %', amount;
END $$;

call PAY(1, 'UPI-095834952839582');

--test admin view
select * from admin_train_overview;
--employee_view
select * from employee_duties(2);
--user bookings
select * from user_bookings(2);
--pnr check
select * from pnr_status(-1);