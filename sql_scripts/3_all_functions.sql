-- Admin view for trains with route and schedule information
CREATE OR REPLACE VIEW admin_train_overview AS
SELECT 
    t.train_id,
    t.name AS train_name,
    start_st.name AS start_station,
    end_st.name AS end_station,
    -- COUNT(DISTINCT s.schedule_id) AS schedule_count,
    COUNT(DISTINCT tk.ticket_id) AS active_tickets,
    COUNT(DISTINCT wl.ticket_id) AS waitlisted_tickets
FROM 
    trains t
    JOIN stations start_st ON t.start_station_id = start_st.station_id
    JOIN stations end_st ON t.end_station_id = end_st.station_id
    LEFT JOIN schedules s ON t.train_id = s.train_id
    LEFT JOIN tickets tk ON t.train_id = tk.train_id AND tk.day_of_ticket >= CURRENT_DATE
    LEFT JOIN waiting_list wl ON t.train_id = wl.train_id AND wl.day_of_ticket >= CURRENT_DATE
GROUP BY 
    t.train_id, t.name, start_st.name, end_st.name;

-- duties view for admin
create or replace view admin_duties_view as 
SELECT 
    d.duty_id,
    d.employee_id,
    e.name AS employee_name,
    d.schedule_ids
FROM 
    Duties d
JOIN 
    Employees e ON d.employee_id = e.employee_id
ORDER BY 
    d.duty_id;

-- -- convert this to function so that each pemployee can only see thier duty
    
create or replace function employee_duties(empl_id int)
returns table(employee_id int, employee_name varchar(100),role varchar(50), duty_id int, schedule_id int,
departure_time time,arrival_time time,day int, train_name varchar(100), departure_station varchar(100),
arrival_station varchar(100))

language plpgsql as $$
begin
	return query
SELECT 
    e.employee_id,
    e.name AS employee_name,
    e.role,
    d.duty_id,
    unnest(d.schedule_ids) AS schedule_id,
    s.departure_time,
    s.arrival_time,
    s.day,
    t.name AS train_name,
    start_st.name AS departure_station,
    end_st.name AS arrival_station
FROM 
    employees e
    JOIN duties d ON e.employee_id = d.employee_id
    JOIN schedules s ON s.schedule_id = ANY(d.schedule_ids)
    JOIN trains t ON s.train_id = t.train_id
    JOIN routes r ON s.route_id = r.route_id
    JOIN stations start_st ON r.start_station_id = start_st.station_id
    JOIN stations end_st ON r.end_station_id = end_st.station_id
	where e.employee_id=empl_id;
end;
$$;

-- User view for bookings (tickets and waitlist) function

create or replace function user_bookings(usr_id int)
returns table(user_id int, username varchar(20), status text, ticket_id int, train_name varchar(20),
boarding_station varchar(100), destination_station varchar(100), journey_date timestamp, passenger_name varchar(100),
seat_num varchar(10), boggie varchar(10), berth varchar(10), class varchar(20), paid_amount numeric)

language plpgsql as $$

begin
return query

SELECT
    u.user_id,
    u.username,
    'Confirmed' AS status,
    tk.ticket_id,
    tr.name AS train_name,
    start_st.name AS boarding_station,
    end_st.name AS destination_station,
    tk.day_of_ticket AS journey_date,
    p.name AS passenger_name,
    s.seat_num,
    s.boggie,
    s.berth,
    s.class,
    COALESCE(pay.amount, 0) AS paid_amount
FROM
    users u
    JOIN tickets tk ON u.user_id = tk.ticket_user
    JOIN trains tr ON tk.train_id = tr.train_id
    JOIN stations start_st ON tk.start_station_id = start_st.station_id
    JOIN stations end_st ON tk.end_station_id = end_st.station_id
    JOIN passengers p ON tk.passenger_id = p.passenger_id
    JOIN seats s ON tk.seat_id = s.seat_id
    LEFT JOIN payments pay ON tk.ticket_id = pay.ticket_id
	where u.user_id=usr_id
UNION ALL
SELECT
    u.user_id,
    u.username,
    'Waitlisted' AS status,
    wl.ticket_id,
    tr.name AS train_name,
    start_st.name AS boarding_station,
    end_st.name AS destination_station,
    wl.day_of_ticket AS journey_date,
    p.name AS passenger_name,
    NULL AS seat_num,
    NULL AS boggie,
    NULL AS berth,
    wl.class,
    COALESCE(pay.amount, 0) AS paid_amount
FROM
    users u
    JOIN waiting_list wl ON u.user_id = wl.ticket_user
    JOIN trains tr ON wl.train_id = tr.train_id
    JOIN stations start_st ON wl.start_station_id = start_st.station_id
    JOIN stations end_st ON wl.end_station_id = end_st.station_id
    JOIN passengers p ON wl.passenger_id = p.passenger_id
    LEFT JOIN payments pay ON wl.ticket_id = pay.ticket_id
	where u.user_id=usr_id;
end;
$$;

-- get train:
create or replace function get_train(ssid int, esid int)
returns table(trainid int, train_name varchar(100))
language plpgsql
as $$
begin
    return query
    (
        select train_id, name from trains where train_id in 
        (
            select train_id from schedules where route_id in 
            (select route_id from routes where start_station_id = ssid)
        ) 
        intersect
        select train_id, name from trains where train_id in 
        (
            select train_id from schedules where route_id in 
            (select route_id from routes where end_station_id = esid)
        )
    );
end;
$$;

--get route:
create or replace function get_route(t_id int)
returns table(station_id integer, station_name VARCHAR(100), day int, arrival_time time, departure_time time, distance numeric(10,2))
language plpgsql
as $$
begin
    return query
    select coalesce(f.station_id, s.station_id), coalesce(f.station_name, s.station_name), 
           coalesce(f.day, s.day), s.arrival_time, f.departure_time,
		   coalesce(s.distance,0)
    from
    (
        select st.station_id as station_id, st.name as station_name, sc.day as day, sc.departure_time as departure_time
        from routes r 
        join (select * from schedules where train_id = t_id) sc 
        on r.route_id = sc.route_id 
        join stations st on r.start_station_id = st.station_id
    ) f
    full outer join
    (
        select st.station_id as station_id, st.name as station_name, sc.day as day, sc.arrival_time as arrival_time, r.distance as distance
        from routes r 
        join (select * from schedules where train_id = t_id) sc 
        on r.route_id = sc.route_id 
        join stations st on r.end_station_id = st.station_id
    ) s
    on f.station_id = s.station_id
    order by coalesce(f.day, s.day), departure_time, arrival_time;
end;
$$;



create or replace function allot(start_station varchar, 
                                  end_station   varchar,
                                  class_name    varchar, 
                                  train_id_arg  integer,
                                  ticket_date   timestamp without time zone)
returns integer
language plpgsql
as $$
declare
    alloc_seat_id integer;
    start_ind     integer;
    end_ind       integer;
begin
	select station_rank
	into start_ind
    from (
        select station_name, row_number() over () as station_rank
        from get_route(train_id_arg)
    ) ranked
    where station_name = start_station;

	select station_rank
	into end_ind   
	from (
       	select station_name, row_number() over () as station_rank
        from get_route(train_id_arg)
    ) ranked
    where station_name = end_station;

    with ranked_stations as (
        select station_id, day, row_number() over () as station_rank
        from get_route(train_id_arg)
    ),
    allocated as (
	    select rs1.station_rank as r1, rs2.station_rank as r2, t.seat_id as sid,
		rs1.day as t1,
		rs2.day as t2,
		ticket_date as tt,
		date_trunc('week', t.day_of_ticket) + (rs1.day - 1) * INTERVAL '1 day' as start_day,
		date_trunc('week', t.day_of_ticket) + (rs2.day - 1) * INTERVAL '1 day' as end_day
	    from tickets t
	    join ranked_stations rs1 on t.start_station_id = rs1.station_id
	    join ranked_stations rs2 on t.end_station_id = rs2.station_id
	    join seats s on s.seat_id = t.seat_id
	    where t.train_id = train_id_arg
	    and s.class = class_name
	    and (
	        (
	            rs1.day <= rs2.day
	            and 
	            (date_trunc('week', t.day_of_ticket) + (rs1.day - 1) * INTERVAL '1 day')::date <= ticket_date::date
	            and 
	            ticket_date::date <= (date_trunc('week', t.day_of_ticket) + (rs2.day - 1) * INTERVAL '1 day')::date
	        )
	        or (
	            rs1.day > rs2.day
	            and (
	                (date_trunc('week', t.day_of_ticket) + (rs1.day - 1) * INTERVAL '1 day')::date <= ticket_date::date
	                or ticket_date::date <= (date_trunc('week', t.day_of_ticket) + (rs2.day - 1) * INTERVAL '1 day')::date
	            )
	        )
	    )
	),
	unallocated as (
        select s.seat_id as sid
        from seats s
        where s.train_id = train_id_arg
        and s.class = class_name
        except
        select sid from allocated
    )
	select coalesce(
        (select sid from allocated
         where r2 <= start_ind or r1 >= end_ind
         order by least(start_ind - r2, r1 - end_ind)
         limit 1),
        (select sid from unallocated  ORDER  BY sid limit 1)
    ) into alloc_seat_id;

    if alloc_seat_id is null then
        alloc_seat_id := -1;
    end if;

    return alloc_seat_id;

end;
$$;
-- Create stored procedure for password change
CREATE OR REPLACE PROCEDURE change_password(
    p_user_id INTEGER,
    p_new_password VARCHAR(255)
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE users SET password = p_new_password WHERE user_id = p_user_id;
    DELETE FROM password_reset_tokens WHERE user_id = p_user_id;
END;
$$;

-- Function to register new users
CREATE OR REPLACE FUNCTION register_user(
    p_username VARCHAR(20),
    p_password VARCHAR(255),
    p_email VARCHAR(100),
    p_phone VARCHAR(20)
)
RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
    new_user_id INTEGER;
    new_role    varchar(100);
BEGIN
    -- Check if username already exists
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        RAISE EXCEPTION 'Username already exists';
    END IF;
    
    -- Get next user ID
    SELECT COALESCE(MAX(user_id), 0) + 1 INTO new_user_id FROM users;

    -- Insert new user with default role as 'user'
    INSERT INTO users (user_id, username, password, role_id)
    VALUES (new_user_id, p_username, p_password,
           (SELECT role_id FROM user_roles WHERE role_name = 'user_role'));
    
    -- -- Create passenger record for the user
    -- INSERT INTO passengers (name, email, phone)
    -- VALUES (p_username, p_email, p_phone);
    
    RETURN new_user_id;
END;
$$;

-- Function to book a ticket
CREATE OR REPLACE FUNCTION book_ticket(
    p_user_id INTEGER,
    p_train_id INTEGER,
    p_start_station VARCHAR(100),
    p_end_station VARCHAR(100),
    p_passenger_id INTEGER,
    p_class VARCHAR(20),
    p_journey_date TIMESTAMP
)
RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
    start_station_id INTEGER;
    end_station_id INTEGER;
    seat_id INTEGER;
    new_ticket_id INTEGER;
BEGIN
    -- Get station IDs
    SELECT station_id INTO start_station_id FROM stations WHERE name = p_start_station;
    SELECT station_id INTO end_station_id FROM stations WHERE name = p_end_station;
    
    IF start_station_id IS NULL OR end_station_id IS NULL THEN
        RAISE EXCEPTION 'Invalid station names';
    END IF;
    
    -- Try to allocate a seat
    SELECT allot(p_start_station, p_end_station, p_class, p_train_id, p_journey_date) INTO seat_id;
    
    -- If seat allocation successful, create ticket
    IF seat_id != -1 THEN
        -- Get next ticket ID
        SELECT nextval('shared_ticket_id') INTO new_ticket_id;
        
        INSERT INTO tickets (
            ticket_id, train_id, seat_id, ticket_user, day_of_ticket, 
            start_station_id, end_station_id, passenger_id
        ) VALUES (
            new_ticket_id, p_train_id, seat_id, p_user_id, p_journey_date,
            start_station_id, end_station_id, p_passenger_id
        );
    ELSE
        -- If no seats available, add to waiting list
        SELECT nextval('shared_ticket_id') INTO new_ticket_id;
        
        INSERT INTO waiting_list (
            ticket_id, train_id, ticket_user, day_of_ticket,
            start_station_id, end_station_id, passenger_id, class
        ) VALUES (
            new_ticket_id, p_train_id, p_user_id, p_journey_date,
            start_station_id, end_station_id, p_passenger_id, p_class
        );
    END IF;

    call pay(new_ticket_id);
    commit;
    RETURN new_ticket_id;
END;
$$;

-- Function to get user's tickets
CREATE OR REPLACE FUNCTION get_user_tickets(p_user_id INTEGER)
RETURNS TABLE (
    ticket_id INTEGER,
    status VARCHAR,
    train_name VARCHAR,
    start_station VARCHAR,
    end_station VARCHAR,
    journey_date TIMESTAMP,
    class VARCHAR,
    seat_info VARCHAR,
    amount DECIMAL(10,2)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.ticket_id,
        b.status,
        b.train_name,
        b.boarding_station,
        b.destination_station,
        b.journey_date,
        b.class,
        CASE WHEN b.status = 'Confirmed' 
             THEN CONCAT(b.boggie, '-', b.seat_num, ' (', b.berth, ')')
             ELSE 'Waiting' END AS seat_info,
        b.paid_amount
    FROM
        user_bookings b
    WHERE
        b.user_id = p_user_id
    ORDER BY
        b.journey_date;
END;
$$;

-- Function to cancel ticket
CREATE OR REPLACE FUNCTION cancel_ticket(
    p_user_id INTEGER,
    p_ticket_id INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
DECLARE
    ticket_exists BOOLEAN;
    is_waiting BOOLEAN;
BEGIN
    -- Check if ticket exists and belongs to user
    SELECT EXISTS (
        SELECT 1 FROM tickets 
        WHERE ticket_id = p_ticket_id AND ticket_user = p_user_id
    ) INTO ticket_exists;
    
    IF ticket_exists THEN
        -- Delete ticket and trigger will handle waitlist processing
        DELETE FROM tickets WHERE ticket_id = p_ticket_id;
        RETURN TRUE;
    END IF;
    
    -- Check if it's a waiting list ticket
    SELECT EXISTS (
        SELECT 1 FROM waiting_list
        WHERE ticket_id = p_ticket_id AND ticket_user = p_user_id
    ) INTO is_waiting;
    
    IF is_waiting THEN
        -- Simply remove from waiting list
        DELETE FROM waiting_list WHERE ticket_id = p_ticket_id;
        RETURN TRUE;
    END IF;
    
    -- Ticket not found or doesn't belong to user
    RETURN FALSE;
END;
$$;

-- Function to search available trains
CREATE OR REPLACE FUNCTION search_trains(
    p_start_station VARCHAR(100),
    p_end_station VARCHAR(100),
    p_journey_date DATE,
    p_preferred_class VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE (
    train_id INTEGER,
    train_name VARCHAR(100),
    departure_time TIME,
    arrival_time TIME,
    journey_day INTEGER,
    available_seats INTEGER,
    fare DECIMAL(10,2),
    travel_time INTERVAL,
    has_waitlist BOOLEAN
)
LANGUAGE plpgsql AS $$
DECLARE
    start_station_id_decl INTEGER;
    end_station_id_decl INTEGER;
BEGIN
    -- Get station IDs
    SELECT station_id INTO start_station_id_decl FROM stations WHERE name = p_start_station;
    SELECT station_id INTO end_station_id_decl FROM stations WHERE name = p_end_station;
    
    IF start_station_id_decl IS NULL OR end_station_id_decl IS NULL THEN
        RAISE EXCEPTION 'Invalid station names';
    END IF;
    
    -- Calculate day of week for journey date
    RETURN QUERY
    WITH available_trains AS (
        SELECT DISTINCT
            t.train_id,
            t.name AS train_name,
            start_sch.departure_time,
            end_sch.arrival_time,
            start_sch.day AS journey_day,
            t.num_seats,
            COALESCE(COUNT(DISTINCT tk.ticket_id), 0) AS booked_seats,
            COALESCE(COUNT(DISTINCT wl.ticket_id), 0) > 0 AS has_waitlist,
            CASE 
                WHEN end_sch.day >= start_sch.day THEN 
                    make_interval(days => (end_sch.day - start_sch.day)::integer) + 
                    (end_sch.arrival_time::interval - start_sch.departure_time::interval)
                ELSE
                    make_interval(days => (end_sch.day + 7 - start_sch.day)::integer) + 
                    (end_sch.arrival_time::interval - start_sch.departure_time::interval)
            END AS travel_time
        FROM
            trains t
            JOIN schedules start_sch ON t.train_id = start_sch.train_id
            JOIN routes start_route ON start_sch.route_id = start_route.route_id
            JOIN schedules end_sch ON t.train_id = end_sch.train_id
            JOIN routes end_route ON end_sch.route_id = end_route.route_id
            LEFT JOIN tickets tk ON t.train_id = tk.train_id AND 
                tk.day_of_ticket = p_journey_date + 
                make_interval(days => CASE 
                    WHEN EXTRACT(DOW FROM p_journey_date) + 1 > start_sch.day 
                    THEN (7 - (EXTRACT(DOW FROM p_journey_date) + 1) + start_sch.day)::integer
                    ELSE (start_sch.day - (EXTRACT(DOW FROM p_journey_date) + 1))::integer
                END)
            LEFT JOIN waiting_list wl ON t.train_id = wl.train_id AND 
                wl.day_of_ticket = p_journey_date + 
                make_interval(days => CASE 
                    WHEN EXTRACT(DOW FROM p_journey_date) + 1 > start_sch.day 
                    THEN (7 - (EXTRACT(DOW FROM p_journey_date) + 1) + start_sch.day)::integer
                    ELSE (start_sch.day - (EXTRACT(DOW FROM p_journey_date) + 1))::integer
                END)
        WHERE
            start_route.start_station_id = start_station_id_decl AND
            end_route.end_station_id = end_station_id_decl AND
            -- start_sch.day <= end_sch.day AND
            (
                (
                    start_sch.day <= end_sch.day
                    and
                    EXTRACT(DOW FROM p_journey_date) between start_sch.day and end_sch.day
                )
                or
                (
                    start_sch.day > end_sch.day
                    and 
                    (
                        EXTRACT(DOW FROM p_journey_date) >= start_sch.day
                        or EXTRACT(DOW FROM p_journey_date) <= end_sch.day
                    )
                )
            ) AND
            (p_preferred_class IS NULL OR EXISTS (
                SELECT 1 FROM seats s 
                WHERE s.train_id = t.train_id AND s.class = p_preferred_class
            ))
        GROUP BY
            t.train_id, t.name, start_sch.departure_time, end_sch.arrival_time,
            start_sch.day, end_sch.day, t.num_seats
    )
    SELECT
        at.train_id,
        at.train_name,
        at.departure_time,
        at.arrival_time,
        at.journey_day,
        (at.num_seats - at.booked_seats)::integer AS available_seats,
        CASE WHEN p_preferred_class IS NULL 
            THEN get_amount(p_start_station, p_end_station, at.train_id, 'General')::numeric
            ELSE get_amount(p_start_station, p_end_station, at.train_id, p_preferred_class)::numeric
        END AS fare,
        at.travel_time,
        at.has_waitlist
    FROM
        available_trains at
    ORDER BY
        at.departure_time;
END;
$$;

create or replace function pnr_status(tk_id int)
returns text
language plpgsql as $$
declare
	status text;
begin

	if exists (select 1 from tickets where ticket_id=tk_id) then
		status:='confirmed';
	elsif exists (select 1 from waiting_list where ticket_id=tk_id) then
		status:='waiting';
	else
		status:='error';
	end if;

	return status;
	
end;
$$;

CREATE OR REPLACE FUNCTION get_amount(
    start_station_name VARCHAR(100),
    end_station_name VARCHAR(100),
    train_id INTEGER,
    class VARCHAR
)
RETURNS FLOAT
AS $$
DECLARE
    per_km_fare FLOAT;
    start_row_id INTEGER;
    end_row_id INTEGER;
    amount FLOAT;

BEGIN
 	
	SELECT price INTO per_km_fare FROM fare_per_km fpk
    WHERE fpk.class = get_amount.class;

    WITH routes_r AS (
        SELECT station_name, distance, ROW_NUMBER() OVER () AS row_num FROM get_route(train_id)
    )
	
    SELECT r1.row_num, r2.row_num INTO start_row_id, end_row_id FROM routes_r r1, routes_r r2
    WHERE r1.station_name = start_station_name AND r2.station_name = end_station_name;

    WITH routes_r AS (
        SELECT station_name, distance, ROW_NUMBER() OVER () AS row_num FROM get_route(train_id)
    )
    SELECT COALESCE(SUM(distance * per_km_fare), 0.0) INTO amount FROM routes_r
    WHERE row_num > start_row_id AND row_num <= end_row_id;

    RETURN amount;
	
END;
$$ LANGUAGE plpgsql;
-- DROP PROCEDURE pay(integer,character varying);
-- CREATE OR REPLACE PROCEDURE PAY(TICKET_ID INTEGER, BANK_DETAILS VARCHAR(20))

CREATE OR REPLACE PROCEDURE PAY(TICKET_ID INTEGER, BANK_DETAILS VARCHAR(20) DEFAULT NULL)
AS $$
DECLARE 
    train_id INTEGER;
    start_station_name VARCHAR(255);
    end_station_name VARCHAR(255);
    seat_class VARCHAR(50);
    amount FLOAT;
BEGIN
    -- First try to get data from the 'tickets' table (Confirmed ticket)
    BEGIN
        SELECT 
            t.train_id, 
            (SELECT st.name FROM stations st WHERE st.station_id = t.start_station_id), 
            (SELECT st.name FROM stations st WHERE st.station_id = t.end_station_id),
            s.class
        INTO train_id, start_station_name, end_station_name, seat_class
        FROM tickets t
        JOIN seats s ON s.seat_id = t.seat_id
        WHERE t.ticket_id = PAY.TICKET_ID;

    EXCEPTION WHEN NO_DATA_FOUND THEN
        -- If not found in 'tickets', try 'waiting_list' instead
        SELECT 
            wl.train_id,
            (SELECT st.name FROM stations st WHERE st.station_id = wl.start_station_id), 
            (SELECT st.name FROM stations st WHERE st.station_id = wl.end_station_id),
            wl.class
        INTO train_id, start_station_name, end_station_name, seat_class
        FROM waiting_list wl
        WHERE wl.ticket_id = PAY.TICKET_ID;
    END;

    -- Compute amount
    SELECT GET_AMOUNT(start_station_name, end_station_name, train_id, seat_class)
    INTO amount;

    -- Insert payment record
    INSERT INTO Payments (ticket_id, amount, bank_details)
    VALUES (TICKET_ID, amount, BANK_DETAILS);

END;
$$ LANGUAGE plpgsql;

--add_ticket_on_cancel from waiting list
create or replace procedure add_ticket_on_cancel(tk_id int)
language plpgsql as $$
declare 
	s_date date;
	trn_id int;
	tmp int;
	i record;
	start_station varchar(100);
	end_station varchar(100);
begin
	-- selecting train_id and start_date
	select train_id, day_of_ticket::DATE into trn_id,s_date from tickets where ticket_id=tk_id;


	-- deleting from tickets table for allotment function to work
	delete from tickets where ticket_id=tk_id;
	-- also need to refund the payment and delete from the payment table


	-- common cause discussed with asad
	select day into tmp from schedules
	where train_id=trn_id
	order by day desc limit 1;
	
	s_date:=s_date+(tmp-extract(dow from s_date)::int);


	-- main part
	-- iterating over all favourable entries from waiting list and if allotment function
	-- returns something then assiging the ticket to the person and delete its entry from the waiting_list
	
	for i in 
		select * from waiting_list where train_id=trn_id and day_of_ticket::date<=s_date
		for update
	loop

		select name into start_station from stations where station_id=i.start_station_id limit 1;
		select name into end_station from stations where station_id=i.end_station_id limit 1;
		
		select allot (start_station,
					  end_station,
					  i.class,
					  i.train_id,
					  i.day_of_ticket) 
		into tmp;
		

		if tmp <> -1 then
			insert into tickets (ticket_id,train_id,seat_id,ticket_user,day_of_ticket,start_station_id,end_station_id,passenger_id)
			values (i.ticket_id,i.train_id,tmp,i.ticket_user,i.day_of_ticket,i.start_station_id,i.end_station_id,i.passenger_id);
			
			delete from waiting_list where current of i;
		end if;
	end loop;
	

end;
$$;

--del_ticket_log function 
CREATE OR REPLACE FUNCTION del_ticket_log(tikt_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    pasngr_id INTEGER;
BEGIN
    -- First delete payment
    DELETE FROM payments WHERE ticket_id = tikt_id;

    -- Get passenger ID before deleting ticket
    SELECT passenger_id INTO pasngr_id FROM tickets WHERE ticket_id = tikt_id;

    -- Delete ticket
    DELETE FROM tickets WHERE ticket_id = tikt_id;

    -- Delete passenger (only if not referenced elsewhere)
    DELETE FROM passengers WHERE passenger_id = pasngr_id;
END;
$$;

--delete_in_ticket function
CREATE OR REPLACE FUNCTION delete_in_ticket(trains_completed_journey INTEGER[])
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    tikt_id INTEGER;
    r RECORD;
BEGIN
    -- Loop through all tickets for completed trains
    FOR r IN SELECT ticket_id FROM tickets
            WHERE train_id = ANY(trains_completed_journey)
              AND day_of_ticket < CURRENT_DATE
    LOOP
        -- Call ticket deletion with logging
        PERFORM del_ticket_log(r.ticket_id);
    END LOOP;

    RAISE NOTICE 'Completed ticket cleanup for % trains', array_length(trains_completed_journey, 1);
END;
$$;

CREATE EXTENSION IF NOT EXISTS pg_cron;
-- function delete_expired_ticket triggerd at every mid night
CREATE OR REPLACE PROCEDURE delete_expired_ticket()
LANGUAGE plpgsql AS $$
DECLARE
    train_ids               INTEGER[];
    tr_id                   INTEGER;
    t_start_station_id      INTEGER;
    t_end_station_id        INTEGER;
    route_start_station_id  INTEGER;
    route_end_station_id    INTEGER;
    journey_complete        BOOLEAN;
    trains_completed_journey INTEGER[] := '{}';
    prev_day                INTEGER;
    r                       RECORD;
BEGIN
    -- Calculate previous day of week (0=Sunday, 6=Saturday)
    prev_day := EXTRACT(DOW FROM NOW())::INTEGER - 1;
    IF prev_day = -1 THEN
        prev_day := 6;
    END IF;

    -- Get array of distinct train_ids from schedules where day = prev_day
    SELECT ARRAY(SELECT DISTINCT train_id FROM schedules WHERE day = prev_day)
      INTO train_ids;

    -- Loop over each train_id in the array
    FOREACH tr_id IN ARRAY train_ids LOOP
        journey_complete := FALSE;

        -- Retrieve the train's start and end station IDs
        SELECT start_station_id, end_station_id
          INTO t_start_station_id, t_end_station_id
          FROM trains
         WHERE train_id = tr_id;

        -- Loop over all schedule rows (assumed to contain a route_id)
        FOR r IN SELECT route_id FROM schedules WHERE train_id = tr_id LOOP
            -- Retrieve route start and end station IDs from Routes table
            SELECT start_station_id, end_station_id
              INTO route_start_station_id, route_end_station_id
              FROM routes
             WHERE route_id = r.route_id;

            -- Check if the route corresponds to the train's journey
            IF route_start_station_id = t_start_station_id THEN
                -- Found starting segment; do nothing extra
                CONTINUE;
            ELSIF route_end_station_id = t_end_station_id THEN
                journey_complete := TRUE;
                EXIT;  -- Exit inner loop once journey end is found
            END IF;
        END LOOP;

        IF journey_complete THEN
            trains_completed_journey := array_append(trains_completed_journey, tr_id);
        ELSE
            RAISE EXCEPTION 'Issue in schedules for train_id %', tr_id;
        END IF;
    END LOOP;

    -- Delete expired tickets for trains that have completed their journey
    PERFORM delete_in_ticket(trains_completed_journey);
END;
$$;

SELECT cron.schedule(
    'delete-expired-tickets',
    '30 18 * * *',  -- 18:30 UTC = 00:00 AM IST (verify timezone!)
    $$CALL delete_expired_ticket();$$
);