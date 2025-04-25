-- Drop existing indexes first
DROP INDEX IF EXISTS idx_tickets_user_id;
DROP INDEX IF EXISTS idx_tickets_date;
DROP INDEX IF EXISTS idx_tickets_train_date;
DROP INDEX IF EXISTS idx_tickets_train_seat;
DROP INDEX IF EXISTS idx_tickets_stations;
DROP INDEX IF EXISTS idx_tickets_passenger;

DROP INDEX IF EXISTS idx_waitlist_user_id;
DROP INDEX IF EXISTS idx_waitlist_date;
DROP INDEX IF EXISTS idx_waitlist_allocation;

DROP INDEX IF EXISTS idx_schedules_train;
DROP INDEX IF EXISTS idx_schedules_route;

DROP INDEX IF EXISTS idx_users_username;

DROP INDEX IF EXISTS idx_payments_ticket;

DROP INDEX IF EXISTS idx_routes_stations;
DROP INDEX IF EXISTS idx_stations_station_name;

-- tickets
CREATE INDEX idx_tickets_user_id ON tickets using HASH(ticket_user);                -- for status of ticket requested by user in user_bookings
CREATE INDEX idx_tickets_date ON tickets using HASH(day_of_ticket);                 -- for event based deletion of tickets on midnight
CREATE INDEX idx_tickets_train_date ON tickets(train_id, day_of_ticket);            -- allot and search_trains function
CREATE INDEX idx_tickets_stations ON tickets(start_station_id, end_station_id);     -- need to check how many people are travelling between 2 station by admin
CREATE INDEX idx_tickets_passenger ON tickets(passenger_id);                        -- user tickets

-- waiting list
CREATE INDEX idx_waitlist_user_id ON waiting_list using HASH(ticket_user);              -- for status of ticket requested by user in user_bookings
CREATE INDEX idx_waitlist_date ON waiting_list using HASH(day_of_ticket);               -- for event based deletion of tickets on midnight
CREATE INDEX idx_waitlist_allocation ON waiting_list(train_id,day_of_ticket);   -- add_ticket_on_cancel trigger uses this for effecient lookups of waiting list


-- schedules
CREATE INDEX idx_schedules_train ON schedules(train_id, day);                           -- for get_train and get_route function
CREATE INDEX idx_schedules_route ON schedules(route_id);                                -- need to check how many trains pass through this route

-- users
CREATE INDEX idx_users_username ON users using HASH(username);                          -- for effecient lookups during login

-- payments
CREATE INDEX idx_payments_ticket ON payments using HASH(ticket_id);                      s-- for deletion of payments table given ticket_id on ticket cancel

--stations
CREATE INDEX idx_stations_station_name on Stations using HASH(name);
-- additional indexes can be used inside events
-- CREATE INDEX idx_active_tickets ON tickets(train_id, seat_id)
-- WHERE day_of_ticket >= CURRENT_DATE;

-- CREATE INDEX idx_active_waitlist ON waiting_list(train_id, class)
-- WHERE day_of_ticket >= CURRENT_DATE;