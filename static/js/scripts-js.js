/**
 * Railway Management System - Main JavaScript File
 * Handles all client-side functionality, form validation, and AJAX requests
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all components
    initializeNavbarToggle();
    initializeFormValidation();
    initializeSearchForm();
    initializeBookingForm();
    initializePnrForm();
    initializeTicketActions();
    initializeToastNotifications();
    initializePasswordStrengthMeter();
    setupDatepickers();
    setupAutocomplete();
});

/**
 * Mobile Navigation Toggle
 */
function initializeNavbarToggle() {
    const navToggleBtn = document.querySelector('.nav-toggle');
    if (navToggleBtn) {
        navToggleBtn.addEventListener('click', function() {
            const navLinks = document.querySelector('.nav-links');
            navLinks.classList.toggle('show');
        });
    }
}

/**
 * Form Validation
 */
function initializeFormValidation() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
        form.addEventListener('submit', function(event) {
            let formValid = true;
            
            // Required fields validation
            const requiredFields = form.querySelectorAll('[required]');
            requiredFields.forEach(field => {
                if (!field.value.trim()) {
                    formValid = false;
                    showFieldError(field, 'This field is required');
                } else {
                    clearFieldError(field);
                }
            });
            
            // // Email validation
            // const emailFields = form.querySelectorAll('input[type="email"]');
            // emailFields.forEach(field => {
            //     if (field.value.trim() && !isValidEmail(field.value)) {
            //         formValid = false;
            //         showFieldError(field, 'Please enter a valid email address');
            //     }
            // });
            
            // // Phone validation
            // const phoneFields = form.querySelectorAll('input[name*="phone"]');
            // phoneFields.forEach(field => {
            //     if (field.value.trim() && !isValidPhone(field.value)) {
            //         formValid = false;
            //         showFieldError(field, 'Please enter a valid phone number');
            //     }
            // });
            
            // // Password validation
            // const passwordField = form.querySelector('input[name="password"]');
            // const confirmPasswordField = form.querySelector('input[name="confirm_password"]');
            
            // if (passwordField && passwordField.value.trim()) {
            //     if (passwordField.value.length < 8) {
            //         formValid = false;
            //         showFieldError(passwordField, 'Password must be at least 8 characters');
            //     }
                
            //     if (confirmPasswordField && passwordField.value !== confirmPasswordField.value) {
            //         formValid = false;
            //         showFieldError(confirmPasswordField, 'Passwords do not match');
            //     }
            // }
            
            // // Age validation
            // const ageFields = form.querySelectorAll('input[name*="age"]');
            // ageFields.forEach(field => {
            //     if (field.value.trim()) {
            //         const age = parseInt(field.value);
            //         if (isNaN(age) || age < 0 || age > 120) {
            //             formValid = false;
            //             showFieldError(field, 'Please enter a valid age');
            //         }
            //     }
            // });
            
            if (!formValid) {
                event.preventDefault();
            }
        });
    });
}

function showFieldError(field, message) {
    // Remove any existing error message
    clearFieldError(field);
    
    // Create and insert error message
    const errorDiv = document.createElement('div');
    errorDiv.className = 'field-error';
    errorDiv.style.color = '#dc3545';
    errorDiv.style.fontSize = '0.85rem';
    errorDiv.style.marginTop = '5px';
    errorDiv.textContent = message;
    
    field.classList.add('error');
    field.style.borderColor = '#dc3545';
    field.parentNode.appendChild(errorDiv);
}

function clearFieldError(field) {
    const error = field.parentNode.querySelector('.field-error');
    if (error) {
        error.remove();
    }
    field.classList.remove('error');
    field.style.borderColor = '';
}

function isValidEmail(email) {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(email);
}

function isValidPhone(phone) {
    const regex = /^\+?[0-9]{10,15}$/;
    return regex.test(phone);
}

/**
 * Train Search Form
 */
function initializeSearchForm() {
    const searchForm = document.getElementById('search-form');
    if (searchForm) {
        // Swap stations button
        const swapButton = document.getElementById('swap-stations');
        if (swapButton) {
            swapButton.addEventListener('click', function() {
                const fromStation = document.getElementById('from-station');
                const toStation = document.getElementById('to-station');
                const tempValue = fromStation.value;
                fromStation.value = toStation.value;
                toStation.value = tempValue;
            });
        }
        
        // AJAX search implementation
        searchForm.addEventListener('submit', function(event) {
            const resultsContainer = document.getElementById('search-results-container');
            
            if (resultsContainer) {
                event.preventDefault();
                
                // Show loading spinner
                resultsContainer.innerHTML = '<div class="text-center p-4"><div class="loading-spinner"></div><p class="mt-3">Searching for trains...</p></div>';
                
                // Get form data
                const formData = new FormData(searchForm);
                const searchParams = new URLSearchParams(formData);
                
                // Make AJAX request
                fetch('/search_trains?' + searchParams.toString())
                    .then(response => response.json())
                    .then(data => {
                        if (data.trains && data.trains.length > 0) {
                            // Render search results
                            renderSearchResults(data.trains, resultsContainer);
                        } else {
                            // No results
                            resultsContainer.innerHTML = '<div class="no-results"><p>No trains found for the selected route and date.</p><p>Please try different stations or dates.</p></div>';
                        }
                    })
                    .catch(error => {
                        console.error('Error searching trains:', error);
                        resultsContainer.innerHTML = '<div class="alert alert-danger">An error occurred while searching. Please try again.</div>';
                    });
            }
        });
    }
}

function renderSearchResults(trains, container) {
    let html = '<div class="search-results fade-in">';
    html += '<h3>Available Trains</h3>';
    html += '<div class="table-responsive">';
    html += '<table class="data-table">';
    html += '<thead><tr><th>Train</th><th>Departure</th><th>Arrival</th><th>Duration</th><th>Available Seats</th><th>Fare</th><th>Action</th></tr></thead>';
    html += '<tbody>';
    
    trains.forEach(train => {
        html += `<tr>
            <td>${train.train_name}</td>
            <td>${train.departure_time}</td>
            <td>${train.arrival_time}</td>
            <td>${train.travel_time}</td>
            <td>${train.available_seats > 0 ? train.available_seats : '<span class="text-warning">Waitlist</span>'}</td>
            <td>₹${train.fare}</td>
            <td><a href="/book/${train.train_id}?date=${train.journey_date}" class="btn btn-primary btn-small">Book</a></td>
        </tr>`;
    });
    
    html += '</tbody></table></div></div>';
    container.innerHTML = html;
}

/**
 * Booking Form
 */
function initializeBookingForm() {
    const bookingForm = document.getElementById('booking-form');
    if (bookingForm) {
        // Class selection - update fare
        const classSelect = document.getElementById('class-select');
        if (classSelect) {
            classSelect.addEventListener('change', function() {
                updateFare();
            });
        }
        
        // Add passenger button
        const addPassengerBtn = document.getElementById('add-passenger');
        if (addPassengerBtn) {
            addPassengerBtn.addEventListener('click', function() {
                const passengersContainer = document.getElementById('passengers-container');
                const passengerCount = passengersContainer.querySelectorAll('.passenger-entry').length;
                
                if (passengerCount < 6) { // Maximum 6 passengers per booking
                    const newPassengerEntry = createPassengerEntry(passengerCount + 1);
                    passengersContainer.appendChild(newPassengerEntry);
                } else {
                    showToast('Maximum 6 passengers allowed per booking', 'warning');
                }
            });
        }
        
        // Initialize passenger section
        const passengersContainer = document.getElementById('passengers-container');
        if (passengersContainer && passengersContainer.children.length === 0) {
            const initialPassenger = createPassengerEntry(1);
            passengersContainer.appendChild(initialPassenger);
        }
        
        // Update fare when form loads
        updateFare();
    }
}

function createPassengerEntry(index) {
    const passengerDiv = document.createElement('div');
    passengerDiv.className = 'passenger-entry card mb-3';
    
    passengerDiv.innerHTML = `
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0">Passenger ${index}</h5>
            ${index > 1 ? '<button type="button" class="btn btn-danger btn-sm remove-passenger">Remove</button>' : ''}
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label for="passenger-name-${index}">Full Name</label>
                    <input type="text" id="passenger-name-${index}" name="passenger_name[]" class="form-control" required>
                </div>
                <div class="col-md-2 mb-3">
                    <label for="passenger-age-${index}">Age</label>
                    <input type="number" id="passenger-age-${index}" name="passenger_age[]" class="form-control" min="1" max="120" required>
                </div>
                <div class="col-md-4 mb-3">
                    <label for="passenger-gender-${index}">Gender</label>
                    <select id="passenger-gender-${index}" name="passenger_gender[]" class="form-control" required>
                        <option value="">Select</option>
                        <option value="Male">Male</option>
                        <option value="Female">Female</option>
                        <option value="Other">Other</option>
                    </select>
                </div>
            </div>
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label for="passenger-phone-${index}">Phone</label>
                    <input type="text" id="passenger-phone-${index}" name="passenger_phone[]" class="form-control">
                </div>
                <div class="col-md-6 mb-3">
                    <label for="passenger-email-${index}">Email</label>
                    <input type="email" id="passenger-email-${index}" name="passenger_email[]" class="form-control">
                </div>
            </div>
        </div>
    `;
    
    // Add event listener to remove button
    const removeBtn = passengerDiv.querySelector('.remove-passenger');
    if (removeBtn) {
        removeBtn.addEventListener('click', function() {
            passengerDiv.remove();
            updateFare();
            // Renumber passenger entries
            const passengerEntries = document.querySelectorAll('.passenger-entry');
            passengerEntries.forEach((entry, i) => {
                const headerText = entry.querySelector('.card-header h5');
                if (headerText) {
                    headerText.textContent = `Passenger ${i + 1}`;
                }
            });
        });
    }
    
    return passengerDiv;
}

function updateFare() {
    const classSelect = document.getElementById('class-select');
    const baseFare = document.getElementById('base-fare');
    const totalFareElement = document.getElementById('total-fare');
    
    if (classSelect && baseFare && totalFareElement) {
        const basePrice = parseFloat(baseFare.dataset.basePrice) || 0;
        const classMultiplier = parseFloat(classSelect.options[classSelect.selectedIndex].dataset.multiplier) || 1;
        const passengerCount = document.querySelectorAll('.passenger-entry').length;
        
        // Calculate total fare
        const totalFare = basePrice * classMultiplier * passengerCount;
        totalFareElement.textContent = `₹${totalFare.toFixed(2)}`;
        
        // Update hidden input with total fare
        const totalFareInput = document.getElementById('total-fare-input');
        if (totalFareInput) {
            totalFareInput.value = totalFare.toFixed(2);
        }
    }
}

/**
 * PNR Status Form
 */
function initializePnrForm() {
    const pnrForm = document.getElementById('pnr-form');
    if (pnrForm) {
        pnrForm.addEventListener('submit', function(event) {
            event.preventDefault();
            
            const pnrInput = document.getElementById('pnr-number');
            const resultContainer = document.getElementById('pnr-result');
            
            if (pnrInput && resultContainer) {
                const pnrNumber = pnrInput.value.trim();
                
                if (!pnrNumber) {
                    showFieldError(pnrInput, 'Please enter a PNR number');
                    return;
                }
                
                // Show loading state
                resultContainer.innerHTML = '<div class="text-center p-4"><div class="loading-spinner"></div><p class="mt-3">Fetching ticket status...</p></div>';
                
                // Make AJAX request
                fetch(`/pnr_status/${pnrNumber}`)
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            renderPnrStatus(data.ticket, resultContainer);
                        } else {
                            resultContainer.innerHTML = `<div class="alert alert-danger">${data.message || 'Invalid PNR number'}</div>`;
                        }
                    })
                    .catch(error => {
                        console.error('Error fetching PNR status:', error);
                        resultContainer.innerHTML = '<div class="alert alert-danger">An error occurred while fetching ticket status. Please try again.</div>';
                    });
            }
        });
    }
}

function renderPnrStatus(ticket, container) {
    let statusClass = 'success';
    if (ticket.status === 'Waitlisted') {
        statusClass = 'warning';
    } else if (ticket.status === 'Cancelled') {
        statusClass = 'danger';
    }
    
    let html = `
        <div class="card pnr-status-card fade-in">
            <div class="card-header">
                <h4 class="mb-0">PNR: ${ticket.ticket_id}</h4>
            </div>
            <div class="card-body">
                <div class="row mb-3">
                    <div class="col-md-6">
                        <strong>Status:</strong> <span class="text-${statusClass}">${ticket.status}</span>
                    </div>
                    <div class="col-md-6">
                        <strong>Train:</strong> ${ticket.train_name}
                    </div>
                </div>
                <div class="row mb-3">
                    <div class="col-md-6">
                        <strong>From:</strong> ${ticket.start_station}
                    </div>
                    <div class="col-md-6">
                        <strong>To:</strong> ${ticket.end_station}
                    </div>
                </div>
                <div class="row mb-3">
                    <div class="col-md-6">
                        <strong>Journey Date:</strong> ${new Date(ticket.journey_date).toLocaleDateString()}
                    </div>
                    <div class="col-md-6">
                        <strong>Class:</strong> ${ticket.class}
                    </div>
                </div>
    `;
    
    if (ticket.seat_info) {
        html += `
            <div class="row mb-3">
                <div class="col-md-6">
                    <strong>Seat:</strong> ${ticket.seat_info}
                </div>
                <div class="col-md-6">
                    <strong>Amount:</strong> ₹${ticket.amount}
                </div>
            </div>
        `;
    }
    
    html += `
                <div class="row mb-3">
                    <div class="col-12">
                        <strong>Passenger:</strong> ${ticket.passenger_name} (${ticket.passenger_age}, ${ticket.passenger_gender})
                    </div>
                </div>
            </div>
        </div>
    `;
    
    container.innerHTML = html;
}

/**
 * Ticket Actions (Cancel, Download, Print)
 */
function initializeTicketActions() {
    // Cancel ticket buttons
    const cancelButtons = document.querySelectorAll('.cancel-ticket-btn');
    cancelButtons.forEach(button => {
        button.addEventListener('click', function(event) {
            event.preventDefault();
            
            const ticketId = this.dataset.ticketId;
            
            if (confirm('Are you sure you want to cancel this ticket? This action cannot be undone.')) {
                // Show loading state
                this.disabled = true;
                this.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Cancelling...';
                
                // Make AJAX request
                fetch(`/cancel_ticket/${ticketId}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRFToken': getCsrfToken()
                    }
                })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            showToast('Ticket cancelled successfully', 'success');
                            
                            // Update UI
                            const ticketCard = this.closest('.ticket-card');
                            const statusElement = ticketCard.querySelector('.ticket-status');
                            
                            if (statusElement) {
                                statusElement.textContent = 'Cancelled';
                                statusElement.className = 'ticket-status text-danger';
                            }
                            
                            // Hide cancel button
                            this.style.display = 'none';
                        } else {
                            showToast(data.message || 'Failed to cancel ticket', 'error');
                            this.disabled = false;
                            this.textContent = 'Cancel Ticket';
                        }
                    })
                    .catch(error => {
                        console.error('Error cancelling ticket:', error);
                        showToast('An error occurred. Please try again.', 'error');
                        this.disabled = false;
                        this.textContent = 'Cancel Ticket';
                    });
            }
        });
    });
    
    // Print ticket buttons
    const printButtons = document.querySelectorAll('.print-ticket-btn');
    printButtons.forEach(button => {
        button.addEventListener('click', function(event) {
            event.preventDefault();
            
            const ticketId = this.dataset.ticketId;
            
            // Open ticket in new window and print
            window.open(`/print_ticket/${ticketId}`, '_blank');
        });
    });
    
    // Download ticket buttons
    const downloadButtons = document.querySelectorAll('.download-ticket-btn');
    downloadButtons.forEach(button => {
        button.addEventListener('click', function(event) {
            event.preventDefault();
            
            const ticketId = this.dataset.ticketId;
            
            // Direct download
            window.location.href = `/download_ticket/${ticketId}`;
        });
    });
}

/**
 * Toast Notifications
 */
function initializeToastNotifications() {
    // Create toast container if not exists
    if (!document.getElementById('toast-container')) {
        const toastContainer = document.createElement('div');
        toastContainer.id = 'toast-container';
        toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
        document.body.appendChild(toastContainer);
    }
    
    // Show existing toasts from server
    const serverToasts = document.querySelectorAll('.server-toast');
    serverToasts.forEach(toast => {
        const message = toast.dataset.message;
        const type = toast.dataset.type || 'info';
        
        if (message) {
            showToast(message, type);
        }
        
        toast.remove();
    });
}

function showToast(message, type = 'info') {
    const toastContainer = document.getElementById('toast-container');
    
    if (!toastContainer) return;
    
    // Get icon and color based on type
    let icon, bgColor;
    switch (type) {
        case 'success':
            icon = '<i class="bi bi-check-circle-fill"></i>';
            bgColor = 'bg-success';
            break;
        case 'error':
        case 'danger':
            icon = '<i class="bi bi-exclamation-circle-fill"></i>';
            bgColor = 'bg-danger';
            break;
        case 'warning':
            icon = '<i class="bi bi-exclamation-triangle-fill"></i>';
            bgColor = 'bg-warning';
            break;
        default:
            icon = '<i class="bi bi-info-circle-fill"></i>';
            bgColor = 'bg-info';
    }
    
    // Create toast element
    const toastId = `toast-${Date.now()}`;
    const toastElement = document.createElement('div');
    toastElement.className = `toast ${bgColor} text-white fade show`;
    toastElement.id = toastId;
    toastElement.role = 'alert';
    toastElement.setAttribute('aria-live', 'assertive');
    toastElement.setAttribute('aria-atomic', 'true');
    
    toastElement.innerHTML = `
        <div class="toast-header ${bgColor} text-white">
            ${icon} <strong class="me-auto">Notification</strong>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
        <div class="toast-body">
            ${message}
        </div>
    `;
    
    // Add to container
    toastContainer.appendChild(toastElement);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        const toast = document.getElementById(toastId);
        if (toast) {
            toast.classList.remove('show');
            setTimeout(() => toast.remove(), 500);
        }
    }, 5000);
    
    // Add close button functionality
    const closeButton = toastElement.querySelector('.btn-close');
    if (closeButton) {
        closeButton.addEventListener('click', function() {
            toastElement.classList.remove('show');
            setTimeout(() => toastElement.remove(), 500);
        });
    }
}

/**
 * Password Strength Meter
 */
function initializePasswordStrengthMeter() {
    const passwordField = document.querySelector('input[name="password"]');
    if (passwordField) {
        const passwordStrengthMeter = document.createElement('div');
        passwordStrengthMeter.className = 'password-strength-meter mt-2';
        passwordStrengthMeter.innerHTML = `
            <div class="progress" style="height: 5px;">
                <div class="progress-bar" role="progressbar" style="width: 0%;" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>
            </div>
            <small class="text-muted mt-1 d-block">Password strength: <span class="strength-text">None</span></small>
        `;
        
        passwordField.parentNode.appendChild(passwordStrengthMeter);
        
        passwordField.addEventListener('input', function() {
            updatePasswordStrength(this.value, passwordStrengthMeter);
        });
    }
}

function updatePasswordStrength(password, meterElement) {
    // Simple password strength algorithm
    let strength = 0;
    const progressBar = meterElement.querySelector('.progress-bar');
    const strengthText = meterElement.querySelector('.strength-text');
    
    if (password.length >= 8) strength += 25;
    if (password.match(/[a-z]/)) strength += 15;
    if (password.match(/[A-Z]/)) strength += 15;
    if (password.match(/[0-9]/)) strength += 15;
    if (password.match(/[^a-zA-Z0-9]/)) strength += 30;
    
    // Update progress bar
    progressBar.style.width = `${strength}%`;
    progressBar.setAttribute('aria-valuenow', strength);
    
    // Update text and color
    let strengthLabel, barColor;
    if (strength < 30) {
        strengthLabel = 'Weak';
        barColor = '#dc3545'; // Red
    } else if (strength < 60) {
        strengthLabel = 'Medium';
        barColor = '#ffc107'; // Yellow
    } else if (strength < 80) {
        strengthLabel = 'Strong';
        barColor = '#0d6efd'; // Blue
    } else {
        strengthLabel = 'Very Strong';
        barColor = '#198754'; // Green
    }
    
    strengthText.textContent = password ? strengthLabel : 'None';
    progressBar.style.backgroundColor = barColor;
}

/**
 * Date Pickers
 */
function setupDatepickers() {
    const datepickers = document.querySelectorAll('.datepicker');
    
    datepickers.forEach(input => {
        // Set min date to today
        const today = new Date();
        const dd = String(today.getDate()).padStart(2, '0');
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const yyyy = today.getFullYear();
        
        // Set min date attribute
        input.setAttribute('min', `${yyyy}-${mm}-${dd}`);
        
        // Set max date to 90 days from now
        const maxDate = new Date();
        maxDate.setDate(maxDate.getDate() + 90);
        const maxDd = String(maxDate.getDate()).padStart(2, '0');
        const maxMm = String(maxDate.getMonth() + 1).padStart(2, '0');
        const maxYyyy = maxDate.getFullYear();
        
        input.setAttribute('max', `${maxYyyy}-${maxMm}-${maxDd}`);
    });
}

/**
 * Station Autocomplete
 */
function setupAutocomplete() {
    const stationInputs = document.querySelectorAll('.station-autocomplete');
    
    stationInputs.forEach(input => {
        input.addEventListener('input', function() {
            const searchText = this.value;
            if (searchText.length < 2) return;
            
            // Make AJAX request for suggestions
            fetch(`/api/stations?query=${encodeURIComponent(searchText)}`)
                .then(response => response.json())
                .then(data => {
                    showAutocompleteResults(this, data.stations);
                })
                .catch(error => {
                    console.error('Error fetching station suggestions:', error);
                });
        });
        
        // Handle focus and blur events
        input.addEventListener('focus', function() {
            if (this.value.length >= 2) {
                const event = new Event('input');
                this.dispatchEvent(event);
            }
        });
        
        input.addEventListener('blur', function() {
            // Delay hiding results to allow clicking on suggestions
            setTimeout(() => {
                hideAutocompleteResults(this);
            }, 200);
        });
    });
}

function showAutocompleteResults(inputElement, stations) {
    // Remove any existing results
    hideAutocompleteResults(inputElement);
    
    if (!stations || stations.length === 0) return;
    
    // Create results container
    const resultsContainer = document.createElement('div');
    resultsContainer.className = 'autocomplete-results';
    
    // Add suggestions
    stations.forEach(station => {
        const suggestion = document.createElement('div');
        suggestion.className = 'autocomplete-suggestion';
        suggestion.textContent = station.name;
        
        suggestion.addEventListener('click', function() {
            inputElement.value = station.name;
            hideAutocompleteResults(inputElement);
            
            // Set hidden input value if it exists
            const hiddenInput = document.getElementById(`${inputElement.id}-id`);
            if (hiddenInput) {
                hiddenInput.value = station.station_id;
            }
        });
        
        resultsContainer.appendChild(suggestion);
    });
    
    // Position and append results
    const rect = inputElement.getBoundingClientRect();
    resultsContainer.style.width = `${rect.width}px`;
    resultsContainer.style.left = `${rect.left}px`;
    resultsContainer.style.top = `${rect.bottom}px`;
    
    document.body.appendChild(resultsContainer);
    inputElement.dataset.hasResults = true;
}

function hideAutocompleteResults(inputElement) {
    if (inputElement.dataset.hasResults) {
        const resultsContainers = document.querySelectorAll('.autocomplete-results');
        resultsContainers.forEach(container => container.remove());
        inputElement.dataset.hasResults = false;
    }
}

/**
 * Helper functions
 */
function getCsrfToken() {
    // Get CSRF token from meta tag
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    return csrfToken || '';
}
