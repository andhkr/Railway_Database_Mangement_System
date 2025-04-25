GRANT ALL PRIVILEGES ON DATABASE postgres TO admin_role;
GRANT CONNECT ON DATABASE postgres TO admin_role;
GRANT USAGE ON SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES TO admin_role;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON SEQUENCES TO admin_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO admin_role;


GRANT EXECUTE ON FUNCTION 
    register_user(varchar(20), varchar(255), varchar(100), varchar(20)),
    pnr_status(int),
    search_trains(varchar(100), varchar(100), date, varchar(20)),
    cancel_ticket(int, int),
    get_user_tickets(int),
    book_ticket(int, int, varchar(100), varchar(100), int, varchar(20), timestamp),
    allot(varchar, varchar, varchar, int, timestamp without time zone),
    user_bookings(int),
    employee_duties(int),
    get_train(int, int),
    get_route(int)
TO employee_role;


GRANT EXECUTE ON FUNCTION 
    register_user(varchar(20), varchar(255), varchar(100), varchar(20)),
    pnr_status(int),
    search_trains(varchar(100), varchar(100), date, varchar(20)),
    cancel_ticket(int, int),
    get_user_tickets(int),
    book_ticket(int, int, varchar(100), varchar(100), int, varchar(20), timestamp),
    allot(varchar, varchar, varchar, int, timestamp without time zone),
    get_train(int, int),
    user_bookings(int),
    get_route(int)
TO user_role;

grant select on fare_per_km,Stations,Routes,users,user_roles,
Trains,Schedules,Passengers,Seats,tickets,waiting_list,
payments,audit_logs
to user_role;

grant insert on Passengers,tickets,waiting_list,users,
payments,audit_logs
to user_role;

grant delete on Passengers,tickets,waiting_list,
payments,audit_logs
to user_role;

GRANT USAGE, SELECT
ON SEQUENCE passengers_passenger_id_seq,audit_logs_log_id_seq,shared_ticket_id,payments_payment_id_seq
TO user_role;

grant select on fare_per_km,Stations,Routes,Employees,users,user_roles,
Trains,Schedules,Duties,Passengers,Seats,tickets,waiting_list,
payments,audit_logs
to employee_role;

grant insert on Passengers,tickets,waiting_list,users,
payments,audit_logs
to employee_role;

grant delete on Passengers,tickets,waiting_list,
payments,audit_logs
to employee_role;

GRANT USAGE, SELECT
ON SEQUENCE passengers_passenger_id_seq,audit_logs_log_id_seq,shared_ticket_id,payments_payment_id_seq
TO employee_role;