import psycopg2
from psycopg2 import pool
import psycopg2.extras
from config import DB_HOST, DB_NAME, DB_USER, DB_PASSWORD, DB_PORT,DB_POOL_MIN_CONN, DB_POOL_MAX_CONN

# Create a global connection pool
connection_pool = None

def initialize_connection_pool():
    """Initialize the connection pool"""
    global connection_pool
    try:
        connection_pool = psycopg2.pool.ThreadedConnectionPool(
            minconn=DB_POOL_MIN_CONN,
            maxconn=DB_POOL_MAX_CONN,
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            port=DB_PORT
        )
        
        # Test the connection by getting and releasing a connection
        test_conn = connection_pool.getconn()
        cursor = test_conn.cursor()
        cursor.execute('SELECT 1')
        cursor.close()
        connection_pool.putconn(test_conn)
        
        print("Successfully connected to the Supabase database")
        return True
    except Exception as e:
        print(f"Error connecting to the database: {e}")
        return False

def get_db_connection():
    """Get a connection from the pool"""
    if connection_pool is None:
        initialize_connection_pool()
    
    conn = connection_pool.getconn()
    return conn

def release_db_connection(conn):
    """Release a connection back to the pool"""
    if connection_pool is not None:
        connection_pool.putconn(conn)

def check_db_connection():
    """Test database connection"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1')
        result = cur.fetchone()
        cur.close()
        release_db_connection(conn)
        return True
    except Exception as e:
        print(f"Database connection test failed: {e}")
        return False

def execute_query(query, params=None, fetch=True):
    """Execute a query and return results if needed"""
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute(query, params)
            if fetch:
                result = cur.fetchall()
                return result
            conn.commit()
            return True
    except Exception as e:
        print(f"Database error: {e}")
        if conn:
            conn.rollback()
        return None
    finally:
        if conn:
            release_db_connection(conn)  # Return to the pool


def call_function(function_name, params=None):
    """Call a PostgreSQL function and return results"""
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            if params:
                cur.callproc(function_name, params)
            else:
                cur.callproc(function_name)
            result = cur.fetchall()
            return result
    except Exception as e:
        print(f"Function call error: {e}")
        if conn:
            conn.rollback()
        return None
    finally:
        if conn:
            release_db_connection(conn)  # Return to the pool


# User authentication methods
def get_user_by_username(username):
    query = "SELECT user_id, username, password, role_id FROM users WHERE username = %s"
    print(username)
    result = execute_query(query, (username,))
    print(result)
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
