import psycopg2
import psycopg2.extras
from config import DATABASE_URI

def get_db_connection():
    """Create a connection to the PostgreSQL database"""
    conn = psycopg2.connect(DATABASE_URI)
    conn.autocommit = True
    return conn

def execute_query(query, params=None, fetch=True):
    """Execute a query and return results if needed"""
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute(query, params)
            if fetch:
                result = cur.fetchall()
                return result
            return True
    except Exception as e:
        print(f"Database error: {e}")
        return None
    finally:
        conn.close()


def call_function(function_name, params=None):
    """Call a PostgreSQL function and return results"""
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            if params:
                cur.callproc(function_name, params)
            else:
                cur.callproc(function_name)
            result = cur.fetchall()
            return result
    except Exception as e:
        print(f"Function call error: {e}")
        return None
    finally:
        conn.close()

# User authentication methods
def get_user_by_username(username):
    query = "SELECT user_id, username, password, role_id FROM users WHERE username = %s"
    result = execute_query(query, (username,))
    return result[0] if result else None

def register_user(username, password, email, phone):
    query = "SELECT register_user(%s, %s, %s, %s)"
    result = execute_query(query, (username, password, email, phone))
    return result[0][0] if result else None

def change_user_password(user_id, new_password):
    query = "CALL change_password(%s, %s)"
    return execute_query(query, (user_id, new_password), fetch=False)

# Train search and ticket booking
def search_available_trains(start_station, end_station, journey_date, preferred_class=None):
    params = [start_station, end_station, journey_date]
    if preferred_class:
        params.append(preferred_class)
        query = "SELECT * FROM search_trains(%s, %s, %s, %s)"
    else:
        query = "SELECT * FROM search_trains(%s, %s, %s)"
    return execute_query(query, params)

def book_new_ticket(user_id, train_id, start_station, end_station, passenger_id, class_name, journey_date):
    query = "SELECT book_ticket(%s, %s, %s, %s, %s, %s, %s)"
    
    result = execute_query(query, (user_id, train_id, start_station, end_station, passenger_id, class_name, journey_date))
    
    return result[0][0] if result else None

def get_ticket_status(ticket_id):
    query = "SELECT pnr_status(%s)"
    result = execute_query(query, (ticket_id,))
    return result[0][0] if result else None

def cancel_user_ticket(user_id, ticket_id):
    query = "SELECT cancel_ticket(%s, %s)"
    result = execute_query(query, (user_id, ticket_id))
    return result[0][0] if result else False

def get_user_bookings(user_id):
    query = "SELECT * FROM user_bookings(%s)"
    return execute_query(query, (user_id,))

# Admin functions
def get_admin_train_overview():
    query = "SELECT * FROM admin_train_overview"
    return execute_query(query)

# Employee functions
def get_employee_duties(employee_id):
    query = "SELECT * FROM employee_duties(%s)"
    return execute_query(query, (employee_id,))

# Station and train data
def get_all_stations():
    query = "SELECT station_id, name FROM stations ORDER BY name"
    return execute_query(query)

def get_train_classes():
    query = "SELECT class, price FROM fare_per_km"
    return execute_query(query)

def add_passenger(name, gender, age, phone=None, email=None, address=None):
    query = """
    INSERT INTO passengers (name, gender, age, phone, email, address)
    VALUES (%s, %s, %s, %s, %s, %s) RETURNING passenger_id
    """
    result = execute_query(query, (name, gender, age, phone, email, address))
    return result[0][0] if result else None
