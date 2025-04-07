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
    get_employee_duties, get_all_stations, get_train_classes, add_passenger,get_db_connection
)
from config import SECRET_KEY

app = Flask(__name__)
app.secret_key = SECRET_KEY

def initialize_database():
    conn = get_db_connection()
    cur = conn.cursor()

    # Get all SQL files from the sql_scripts directory
    # Assuming you have a directory called sql_scripts in your project root
    sql_files = sorted(glob.glob('sql_scripts/*.sql'))

    print(f"Found {len(sql_files)} SQL files to execute")

    for sql_file in sql_files:
        print(f"Executing {sql_file}...")
        try:
            with open(sql_file, 'r') as f:
                sql_script = f.read()
                cur.execute(sql_script)
            print(f"Successfully executed {sql_file}")
        except Exception as e:
            print(f"Error executing {sql_file}: {e}")

    cur.close()
    conn.close()
    print("Database initialization completed")

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
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        user = get_user_by_username(username)
        
        if user and check_password_hash(user['password'], password):
            # Store user info in session
            session['user_id'] = user['user_id']
            session['username'] = user['username']
            session['role_id'] = user['role_id']
            
            # Redirect based on role
            if user['role_id'] == 1:  # Admin
                return redirect(url_for('admin_dashboard'))
            elif user['role_id'] == 2:  # Employee
                return redirect(url_for('employee_dashboard'))
            else:  # Regular user
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
    """Admin dashboard route"""
    if not is_logged_in() or get_user_role() != 1:
        flash('Unauthorized access')
        return redirect(url_for('login'))
    
    trains_overview = get_admin_train_overview()
    return render_template('admin_dashboard.html', trains=trains_overview)

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

@app.route('/book-ticket/<int:train_id>', methods=['GET', 'POST'])
def book_ticket(train_id):
    """Ticket booking route"""
    if not is_logged_in():
        return redirect(url_for('login'))
    
    # Get available classes for this train
    train_classes = get_train_classes()
    stations = get_all_stations()
    
    if request.method == 'POST':
        start_station = request.form.get('start_station')
        end_station = request.form.get('end_station')
        passenger_name = request.form.get('passenger_name')
        passenger_age = request.form.get('passenger_age')
        passenger_gender = request.form.get('passenger_gender')
        passenger_phone = request.form.get('passenger_phone')
        selected_class = request.form.get('class')
        journey_date = request.form.get('journey_date')
        
        # Add passenger to database
        passenger_id = add_passenger(passenger_name, passenger_gender, passenger_age, passenger_phone)
        
        if not passenger_id:
            flash('Error adding passenger details')
            return redirect(url_for('search_trains'))
        
        # Book ticket
        ticket_id = book_new_ticket(
            session.get('user_id'),
            train_id,
            start_station,
            end_station,
            passenger_id,
            selected_class,
            journey_date
        )
        
        if ticket_id:
            flash(f'Ticket booked successfully! Your PNR is {ticket_id}')
            return redirect(url_for('my_tickets'))
        else:
            flash('Ticket booking failed. Train might be full.')
            return redirect(url_for('search_trains'))
    
    return render_template('book_ticket.html', 
                          train_id=train_id, 
                          stations=stations, 
                          train_classes=train_classes)

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

if __name__ == '__main__':
    initialize_database()
    app.run(debug=True)
