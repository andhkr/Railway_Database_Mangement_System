import os
import glob
import psycopg2
from flask import Flask, render_template, request, redirect, url_for, flash, session, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
import datetime
from models.database import (
    get_user_by_username, register_user, change_user_password,
    search_available_trains, book_new_ticket, get_ticket_status,
    cancel_user_ticket, get_user_bookings, get_admin_train_overview,
    get_employee_duties, get_all_stations, get_train_classes, add_passenger,get_db_connection,initialize_connection_pool,check_db_connection,
    release_db_connection,session_role_id,get_connection_for_request,get_employee_table,get_schedules_table,get_duties_overview,update_schedule
)
from config import SECRET_KEY
import json
import atexit
app = Flask(__name__)
app.secret_key = SECRET_KEY

# Initialize the database connection pool at startup
if initialize_connection_pool():
    print("Database connection pool initialized successfully.")
else:
    print("Failed to initialize database connection pool. Check your credentials.")
    # Depending on your requirements, you might want to exit the application here
    # import sys
    # sys.exit(1)

# Test the connection
if check_db_connection():
    print("Database connection test successful. and role_id")
else:
    print("Database connection test failed.")

# Register function to close pool at application exit
def close_connection_pool():
    from models.database import connection_pool
    if connection_pool:
        connection_pool.closeall()
        print("Database connection pool closed.")

atexit.register(close_connection_pool)

def initialize_database():
    conn = get_db_connection()
    conn.autocommit = False  # Turn off autocommit for transaction
    cur = conn.cursor()

    try:
        # Get all SQL files from the sql_scripts directory
        # Assuming you have a directory called sql_scripts in your project root
        # sql_files = sorted(glob.glob('sql_scripts/*.sql'))

        # print(f"Found {len(sql_files)} SQL files to execute")

        # for sql_file in sql_files:
        #     print(f"Executing {sql_file}...")
        #     try:
        #         with open(sql_file, 'r') as f:
        #             sql_script = f.read()
        #             cur.execute(sql_script)
        #         print(f"Successfully executed {sql_file}")
        #     except Exception as e:
        #         print(f"Error executing {sql_file}: {e}")
        
        # cur.execute("SELECT user_id, password FROM users")
        # users = cur.fetchall()
        
        # # Update each user's password with a hashed version
        # for user_id, plain_password in users:
        #     hashed_password = generate_password_hash(plain_password)
        #     cur.execute(
        #         "UPDATE users SET password = %s WHERE user_id = %s",
        #         (hashed_password, user_id)
        #     )
        # hashed_password = generate_password_hash("rajesh1")
        # cur.execute(
        #         """
        #         INSERT INTO users (user_id,username,password,role_id)VALUES
        #         (%s,%s,%s,%s)
        #         """,
        #         (8,'_rajesh',hashed_password,2)
        #     )
        # hashed_password = generate_password_hash("priya2")
        # cur.execute(
        #         """
        #         INSERT INTO users (user_id,username,password,role_id)VALUES
        #         (%s,%s,%s,%s)
        #         """,
        #         (9,'_priya',hashed_password,2)
        #     )
        # conn.commit()
        print("Database initialization completed successfully")
    except Exception as e:
        # Roll back on error
        conn.rollback()
        print(f"Error during database initialization: {e}")
    finally:
        cur.close()
        release_db_connection(conn)  # Return connection to pool

# Helper function to check if user is logged in
def is_logged_in():
    return 'user_id' in session

# Helper function to get current user role
def get_user_role():
    return session.get('role_id')

@app.route('/')
def index():
    """Home page route"""
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    """User login route"""
    global session_role_id
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        user = get_user_by_username(username)
        
        if user and check_password_hash(user['password'], password):
            # Store user info in session
            session['user_id'] = user['user_id']
            session['username'] = user['username']
            session['role_id'] = user['role_id']
            session_role_id = user['role_id']
            
            # Redirect based on role
            if user['role_id'] == 1:  # Admin
                # set_role_for_user(1)
                return redirect(url_for('admin_dashboard'))
            elif user['role_id'] == 2:  # Employee
                # set_role_for_user(2)
                return redirect(url_for('employee_dashboard'))
            else:  # Regular user
                # set_role_for_user(0)
                return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password')
    
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    """User registration route"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        email = request.form.get('email')
        phone = request.form.get('phone')
        
        # Check if username already exists
        if get_user_by_username(username):
            flash('Username already exists')
            return render_template('register.html')
        
        # Hash password
        hashed_password = generate_password_hash(password)
        
        # Register user
        user_id = register_user(username, hashed_password, email, phone)
        
        if user_id:
            flash('Registration successful! Please login.')
            return redirect(url_for('login'))
        else:
            flash('Registration failed')
    
    return render_template('register.html')

@app.route('/logout')
def logout():
    """Logout route"""
    session.clear()
    flash('You have been logged out')
    return redirect(url_for('index'))

@app.route('/dashboard')
def dashboard():
    """User dashboard route"""
    if not is_logged_in():
        return redirect(url_for('login'))
    
    return render_template('dashboard.html', username=session.get('username'))

@app.route('/admin/dashboard')
def admin_dashboard():
    """Render the admin dashboard with train, employee, schedule, and duty data"""
    try:
        trains_overview = get_admin_train_overview()
        employees       = get_employee_table()
        schedules       = get_schedules_table()
        duties          = get_duties_overview()
        
        return render_template(
            'admin_dashboard.html', 
            trains=trains_overview,
            employees=employees,
            schedules=schedules,
            duties=duties
        )
        
    except Exception as e:
        print(f"Error loading admin dashboard: {str(e)}")
        flash(f'Error loading dashboard: {str(e)}', 'error')
        return redirect(url_for('home'))

@app.route('/employee/dashboard')
def employee_dashboard():
    """Employee dashboard route"""
    if not is_logged_in() or get_user_role() != 2:
        flash('Unauthorized access')
        return redirect(url_for('login'))
    
    duties = get_employee_duties(session.get('user_id'))
    return render_template('employee_dashboard.html', duties=duties)

@app.route('/search-trains', methods=['GET', 'POST'])
def search_trains():
    """Train search route"""
    if not is_logged_in():
        return redirect(url_for('login'))
    
    stations = get_all_stations()
    train_classes = get_train_classes()
    
    if request.method == 'POST':
        start_station = request.form.get('start_station')
        end_station = request.form.get('end_station')
        journey_date = request.form.get('journey_date')
        preferred_class = request.form.get('preferred_class')
        
        # Search for available trains
        trains = search_available_trains(start_station, end_station, journey_date, preferred_class)
        # print(trains)
        return render_template('search_trains.html', 
                              stations=stations, 
                              train_classes=train_classes, 
                              trains=trains,
                              search_params={
                                  'start_station': start_station,
                                  'end_station': end_station,
                                  'journey_date': journey_date,
                                  'preferred_class': preferred_class
                              })
    
    return render_template('search_trains.html', stations=stations, train_classes=train_classes)

# @app.route('/book-ticket/<int:train_id>', methods=['GET', 'POST'])
# @app.route('/book_ticket/<int:train_id>', methods=['GET', 'POST'])
@app.route('/book_ticket/<int:train_id>', methods=['GET', 'POST'])
def book_ticket(train_id):
    """Ticket booking route"""
    if not is_logged_in():
        return redirect(url_for('login'))

    # Get form data options
    train_classes = get_train_classes()
    stations = get_all_stations()

    if request.method == 'POST':
        conn = None
        try:
            # Parse form inputs
            start_station = request.form['start_station']
            end_station = request.form['end_station']
            selected_class = request.form['class']
            journey_date = request.form['journey_date']

            # Primary passenger data
            passenger_name = request.form['passenger_name']
            passenger_age = int(request.form['passenger_age'])
            passenger_gender = request.form['passenger_gender']
            passenger_phone = request.form['passenger_phone']

            # Connect and begin transaction
            conn = get_connection_for_request()
            conn.autocommit = False
            cur = conn.cursor()

            # Insert primary passenger
            cur.execute(
                """
                INSERT INTO passengers (name, gender, age, phone)
                VALUES (%s, %s, %s, %s)
                RETURNING passenger_id
                """,
                (passenger_name, passenger_gender, passenger_age, passenger_phone)
            )
            primary_pid = cur.fetchone()[0]
            if not primary_pid:
                raise Exception('Could not add primary passenger')

            # Book primary ticket via stored function
            cur.execute(
                "SELECT book_ticket(%s, %s, %s, %s, %s, %s, %s)",
                (session['user_id'], train_id, start_station, end_station,
                 primary_pid, selected_class, journey_date)
            )
            primary_ticket = cur.fetchone()[0]
            if not primary_ticket:
                raise Exception('Primary ticket booking failed (likely full)')

            # Handle additional passengers JSON list
            additional_json = request.form.get('additional_passengers', '[]')
            additional = json.loads(additional_json)
            booked_count = 1

            for p in additional:
                name = p.get('name')
                age = p.get('age')
                gender = p.get('gender')
                phone = p.get('phone')
                if not all([name, age, gender, phone]):
                    continue

                # Insert additional passenger
                cur.execute(
                    "INSERT INTO passengers (name, gender, age, phone) VALUES (%s, %s, %s, %s) RETURNING passenger_id",  
                    (name, gender, int(age), phone)
                )
                add_pid = cur.fetchone()[0]
                if not add_pid:
                    raise Exception(f'Failed to add passenger {name}')

                # Book additional ticket
                cur.execute(
                    "SELECT book_ticket(%s, %s, %s, %s, %s, %s, %s)",
                    (session['user_id'], train_id, start_station, end_station,
                     add_pid, selected_class, journey_date)
                )
                ticket_id = cur.fetchone()[0]
                if not ticket_id:
                    raise Exception(f'Booking failed for passenger {name}')
                booked_count += 1

            conn.commit()

            flash(f'Successfully booked {booked_count} ticket(s)! PNR: {primary_ticket}', 'success')
            return redirect(url_for('my_tickets'))

        except Exception as e:
            if conn:
                conn.rollback()
            flash(str(e), 'error')
            return redirect(url_for('search_trains'))

        finally:
            if conn:
                conn.close()

    # GET request
    return render_template(
        'book_ticket.html',
        train_id=train_id,
        stations=stations,
        train_classes=train_classes
    )

@app.route('/my-tickets')
def my_tickets():
    """User tickets route"""
    if not is_logged_in():
        return redirect(url_for('login'))
    
    tickets = get_user_bookings(session.get('user_id'))
    return render_template('my_tickets.html', tickets=tickets)

@app.route('/cancel-ticket/<int:ticket_id>', methods=['POST'])
def cancel_ticket(ticket_id):
    """Cancel ticket route"""
    if not is_logged_in():
        return redirect(url_for('login'))
    
    success = cancel_user_ticket(session.get('user_id'), ticket_id)
    
    if success:
        flash('Ticket cancelled successfully')
    else:
        flash('Failed to cancel ticket')
    
    return redirect(url_for('my_tickets'))

@app.route('/check-pnr', methods=['GET', 'POST'])
def check_pnr():
    """PNR status check route"""
    if request.method == 'POST':
        pnr = request.form.get('pnr')
        status = get_ticket_status(pnr)
        
        return render_template('train_status.html', status=status, pnr=pnr)
    
    return render_template('train_status.html')

@app.route('/api/stations')
def api_stations():
    """API route to get all stations"""
    stations = get_all_stations()
    return jsonify(stations)

@app.route('/add_employee', methods=['POST'])
def add_employee():
    conn = None
    if request.method == 'POST':
        try:
            # Get employee data from form
            employee_id = request.form['EmployeeID']
            name = request.form['name']
            gender = request.form['gender']
            age = request.form['age'] if request.form['age'] else None
            phone = request.form['phone']
            email = request.form['email']
            address = request.form['address']
            role = request.form['role']
            salary = request.form['salary'] if request.form['salary'] else None
            # Get duties data
            schedule_ids_str = request.form['schedule_ids']
            # Convert comma-separated string to array of integers
            schedule_ids = [int(id.strip()) for id in schedule_ids_str.split(',') if id.strip()]
            
            # Get user account data
            username = request.form['username']
            password = request.form['password']
            hashed_password = generate_password_hash(password)
          
            # Connect to database
            conn = get_connection_for_request()
            cur = conn.cursor()
            
            # Begin transaction
            conn.autocommit = False
            
            # 1. Insert into Employees table and get the new employee_id
            cur.execute(
                """
                INSERT INTO Employees (employee_id,name, gender, age, phone, email, address, role, salary)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING employee_id
                """, 
                (employee_id,name, gender, age, phone, email, address, role, salary)
            )
            
            # 2. Insert into users table
            # First, get the role_id for 'employee'
            cur.execute("SELECT role_id FROM user_roles WHERE role_name = 'employee_role'")
            role_id = cur.fetchone()[0]
            
            cur.execute(
                """
                INSERT INTO users (user_id,username, password, role_id)
                VALUES (%s, %s, %s, %s)
                """,
                (employee_id, username, hashed_password, role_id)
            )
            
            # 3. Insert into Duties table
            print(schedule_ids)
            if schedule_ids:
                cur.execute(
                    """
                    INSERT INTO Duties (employee_id, schedule_ids)
                    VALUES (%s, %s::integer[])
                    """,
                    (employee_id, schedule_ids)
                )
            
            # Commit the transaction
            conn.commit()
            flash('Employee added successfully!', 'success')
            
        except psycopg2.IntegrityError as e:
            conn.rollback()
            if "unique_duty" in str(e):
                flash('This employee already has assigned duties.', 'error')
            elif "unique" in str(e) and "username" in str(e):
                flash('Username already exists. Please choose another.', 'error')
            else:
                flash(f'Database error: {str(e)}', 'error')
        except Exception as e:
            conn.rollback()
            flash(f'Error: {str(e)}', 'error')
        finally:
            if conn:
                conn.close()
        
        return redirect(url_for('admin_dashboard'))
    
    # This should not be reached if the route is POST only
    return redirect(url_for('admin_dashboard'))

@app.route('/delete_employee')
def delete_employee():
    """Delete an employee"""
    try:
        employee_id = request.args.get('id')
        if not employee_id:
            flash('Employee ID is required', 'error')
            return redirect(url_for('admin_dashboard'))
        
        conn = get_connection_for_request()
        cur = conn.cursor()

        # Begin transaction
        conn.autocommit = False
        
        # First delete from duties (due to foreign key constraint)
        cur.execute("DELETE FROM Duties WHERE employee_id = %s", (employee_id,))

        cur.execute("DELETE FROM users WHERE user_id = %s", (employee_id,))
        
        # Finally delete the employee
        cur.execute("DELETE FROM Employees WHERE employee_id = %s", (employee_id,))
        
        conn.commit()
        flash('Employee deleted successfully', 'success')
        
    except Exception as e:
        if conn:
            conn.rollback()
        flash(f'Error deleting employee: {str(e)}', 'error')
    finally:
        if conn:
            release_db_connection(conn)
            
    return redirect(url_for('admin_dashboard'))

@app.route('/add_Duty', methods=['POST'])
def add_Duty():
    conn = None
    if request.method == 'POST':
        try:
            # Get employee data from form
            employee_id = request.form['employeeID']
            # Get duties data
            schedule_ids_str = request.form['schedule_ids']
            # Convert comma-separated string to array of integers
            schedule_ids = [int(id.strip()) for id in schedule_ids_str.split(',') if id.strip()]
            
            # Connect to database
            conn = get_connection_for_request()
            cur = conn.cursor()
            
            # Begin transaction
            conn.autocommit = False

            if schedule_ids:
                cur.execute(
                    """
                    INSERT INTO Duties (employee_id, schedule_ids)
                    VALUES (%s, %s::integer[])
                    """,
                    (employee_id, schedule_ids)
                )
            
            # Commit the transaction
            conn.commit()
            flash('Duty added successfully!', 'success')
            
        except psycopg2.IntegrityError as e:
            conn.rollback()
            if "unique_duty" in str(e):
                flash('This employee already has assigned duties.', 'error')
            else:
                flash(f'Database error: {str(e)}', 'error')
        except Exception as e:
            conn.rollback()
            flash(f'Error: {str(e)}', 'error')
        finally:
            if conn:
                conn.close()
        
        return redirect(url_for('admin_dashboard'))
    
    # This should not be reached if the route is POST only
    return redirect(url_for('admin_dashboard'))

@app.route('/delete_duty')
def delete_duty():
    """Delete a duty assignment"""
    try:
        duty_id = request.args.get('id')
        if not duty_id:
            flash('Duty ID is required', 'error')
            return redirect(url_for('admin_dashboard'))
        
        conn = get_connection_for_request()
        cur = conn.cursor()
        
        cur.execute("DELETE FROM Duties WHERE duty_id = %s", (duty_id,))
        
        conn.commit()
        flash('Duty deleted successfully', 'success')
        
    except Exception as e:
        if conn:
            conn.rollback()
        flash(f'Error deleting duty: {str(e)}', 'error')
    finally:
        if conn:
            release_db_connection(conn)

    return redirect(url_for('admin_dashboard'))

@app.route('/update_schedule_field', methods=['POST'])
def update_schedule_field():
    data = request.get_json()
    schedule_id = data['schedule_id']
    field = data['field']
    value = data['value']

    try:
        # Update only the specific field in DB
        print("nyo")
        update_schedule(schedule_id, field, value)  # implement this function
        print("nyo")
        return jsonify(success=True)
    except Exception as e:
        print("Error updating field:", e)
        return jsonify(success=False), 500

if __name__ == '__main__':
    # initialize_database()
    app.run(debug=True)
