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

-- tickets
CREATE INDEX idx_tickets_user_id ON tickets(ticket_user);
CREATE INDEX idx_tickets_date ON tickets(day_of_ticket);
CREATE INDEX idx_tickets_train_date ON tickets(train_id, day_of_ticket);
CREATE INDEX idx_tickets_train_seat ON tickets(train_id, seat_id);
CREATE INDEX idx_tickets_stations ON tickets(start_station_id, end_station_id);
CREATE INDEX idx_tickets_passenger ON tickets(passenger_id, day_of_ticket);


-- waiting list
CREATE INDEX idx_waitlist_user_id ON waiting_list(ticket_user);
CREATE INDEX idx_waitlist_date ON waiting_list(day_of_ticket);
CREATE INDEX idx_waitlist_allocation ON waiting_list(train_id, class, day_of_ticket);


-- schedules
CREATE INDEX idx_schedules_train ON schedules(train_id, day);
CREATE INDEX idx_schedules_route ON schedules(route_id);

-- users
CREATE INDEX idx_users_username ON users(username);

-- payments
CREATE INDEX idx_payments_ticket ON payments(ticket_id);

-- additional indexes can be used inside events
-- CREATE INDEX idx_active_tickets ON tickets(train_id, seat_id)
-- WHERE day_of_ticket >= CURRENT_DATE;

-- CREATE INDEX idx_active_waitlist ON waiting_list(train_id, class)
-- WHERE day_of_ticket >= CURRENT_DATE;
