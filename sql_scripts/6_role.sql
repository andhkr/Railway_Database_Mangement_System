CREATE ROLE admin;
CREATE ROLE employee;
CREATE ROLE user;

GRANT ALL PRIVILEGES ON DATABASE <database_name> TO admin;


GRANT EXECUTE ON FUNCTION 
    register_user(varchar(20), varchar(255), varchar(100), varchar(20)),
    pnr_status(int),
    search_trains(varchar(100), varchar(100), date, varchar(20)),
    cancel_ticket(int, int),
    get_user_tickets(int),
    book_ticket(int, int, varchar(100), varchar(100), int, varchar(20), timestamp),
    change_password(int, varchar(255)),
    allot(varchar, varchar, varchar, int, timestamp without time zone),
    user_bookings(int),
    employee_duties(int),
    get_train(int, int),
    get_route(int)
TO employee;

GRANT EXECUTE ON FUNCTION 
    register_user(varchar(20), varchar(255), varchar(100), varchar(20)),
    pnr_status(int),
    search_trains(varchar(100), varchar(100), date, varchar(20)),
    cancel_ticket(int, int),
    get_user_tickets(int),
    book_ticket(int, int, varchar(100), varchar(100), int, varchar(20), timestamp),
    change_password(int, varchar(255)),
    allot(varchar, varchar, varchar, int, timestamp without time zone),
    get_train(int, int),
    user_bookings(int),
    get_route(int)
TO user;
