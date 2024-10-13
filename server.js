require('dotenv').config();

// app.js
const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const { Pool } = require('pg');
const fs = require('fs');
const multer = require('multer'); // Import multer
const path = require('path');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const bcrypt = require('bcryptjs'); // If you're using hashed passwords

const app = express();
const PORT = 3000;

const pool = new Pool({
    connectionString: process.env.POSTGRES_URL,
  })

const uploadDir = path.join(__dirname, 'uploads');

if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Middleware
app.set('views', path.join(__dirname, './views'));
app.set('view engine', 'ejs');
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public'));
app.use(session({
    secret: 'your_secret_key',
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false } // Set to true if using HTTPS
}));

const upload = multer({ dest: 'uploads/' });

app.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).send('No file uploaded.');
    }
    // File is saved, you can now use req.file.path to access the uploaded file
    res.send(`File uploaded successfully: ${req.file.filename}`);
});

// Middleware to check if user is logged in
function ensureAuthenticated(req, res, next) {
    if (req.session && req.session.user) {
        return next();
    } else {
        res.redirect('/login'); // Redirect to login if not authenticated
    }
}

async function getHospitalIdByAdminId(adminId) {
    const query = 'SELECT hospital_id FROM Hospitals WHERE hospital_admin_id = $1';
    const result = await pool.query(query, [adminId]);
    return result.rows.length > 0 ? result.rows[0].hospital_id : null;
}

async function sendNotification(userId, message, status = 'pending') {
    const query = `
        INSERT INTO Notifications (user_id, message, status) 
        VALUES ($1, $2, $3)
    `;

    try {
        await pool.query(query, [userId, message, status]);
    } catch (error) {
        console.error('Error sending notification:', error);
    }
}

// Middleware to check if user is admin
function checkAdmin(req, res, next) {
    console.log('User Role:', req.session.user ? req.session.user.role : 'No user session');
    if (req.session.user && req.session.user.role === 'admin') {
        return next(); // Allow access
    }
    return res.status(403).send('Access denied. Admins only.'); // Deny access
}

// Middleware to parse URL-encoded data
app.use(express.urlencoded({ extended: true }));

// Admin dashboard route with the checkAdmin middleware
app.get('/admin/dashboard', async (req, res) => {
    try {
        // Fetch users
        const usersResult = await pool.query('SELECT * FROM Users');
        const users = usersResult.rows;

        // Fetch hospitals
        const hospitalsResult = await pool.query('SELECT * FROM Hospitals');
        const hospitals = hospitalsResult.rows;

        // Fetch vaccines
        const vaccinesResult = await pool.query('SELECT * FROM Vaccines');
        const vaccines = vaccinesResult.rows;

        // Render the EJS template and pass users, hospitals, and vaccines
        res.render('myadmin-dashboard', { users, hospitals, vaccines, user: req.user });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// Route for deleting a user
app.post('/admin/users/delete/:id', async (req, res) => {
    const userId = req.params.id;
    try {
        await pool.query('DELETE FROM Users WHERE user_id = $1', [userId]);
        res.json({ success: true }); // Return a success response
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, error: 'Server Error' }); // Return an error response
    }
});

// Route for deleting a hospital
app.post('/admin/hospitals/delete/:id', async (req, res) => {
    const hospitalId = req.params.id;
    try {
        await pool.query('DELETE FROM Hospitals WHERE hospital_id = $1', [hospitalId]);
        res.json({ success: true }); // Return a success response
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, error: 'Server Error' }); // Return an error response
    }
});

// Route for deleting a vaccine
app.post('/admin/vaccines/delete/:id', async (req, res) => {
    const vaccineId = req.params.id;
    try {
        await pool.query('DELETE FROM Vaccines WHERE vaccine_id = $1', [vaccineId]);
        res.json({ success: true }); // Return a success response
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, error: 'Server Error' }); // Return an error response
    }
});

// Routes
app.get('/', (req, res) => {
    res.redirect('/login');
});

// Login Route
app.get('/login', (req, res) => {
    res.render('login');
});

// Registration Route
app.get('/register', async (req, res) => {
    try {
        const hospitalsQuery = 'SELECT * FROM Hospitals';
        const hospitalsResult = await pool.query(hospitalsQuery);
        const hospitals = hospitalsResult.rows;

        res.render('register', { hospitals });
    } catch (error) {
        console.error(error);
        res.send('Error fetching hospitals');
    }
});

// Logout Route
app.get('/logout', (req, res) => {
    res.render('login');
});

// Handle Registration
app.post('/register', async (req, res) => {
    const { username, password, email, role, hospital_id } = req.body;

    // Validate role
    if (!['user', 'hospital_admin'].includes(role)) {
        return res.status(400).send('Invalid role specified.');
    }

    try {
        // Check if email already exists
        const emailCheckQuery = 'SELECT * FROM Users WHERE email = $1';
        const emailCheckResult = await pool.query(emailCheckQuery, [email]);

        if (emailCheckResult.rows.length > 0) {
            // Email already exists, render registration page with warning
            const hospitalsQuery = 'SELECT * FROM Hospitals';
            const hospitalsResult = await pool.query(hospitalsQuery);
            const hospitals = hospitalsResult.rows;
            return res.render('register', { hospitals, warning: 'Email already exists. Please use a different email.' });
        }

        // If email is unique, proceed with registration
        const insertQuery = `
            INSERT INTO Users (username, password, email, role, hospital_admin_id) 
            VALUES ($1, $2, $3, $4, $5)
        `;
        await pool.query(insertQuery, [username, password, email, role, role === 'hospital_admin' ? hospital_id : null]);
        res.redirect('/login');
    } catch (error) {
        console.error(error);
        res.send('Error during registration');
    }
});

//Handle Login
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    const query = 'SELECT * FROM Users WHERE username = $1';

    try {
        const result = await pool.query(query, [username]);

        if (result.rows.length > 0) {
            const user = result.rows[0];

            // Password validation (plain text comparison as you're not using bcrypt)
            const isValidPassword = password === user.password;

            if (isValidPassword) {
                // Storing user data in session based on role
                req.session.user = {
                    user_id: user.user_id,
                    username: user.username,
                    role: user.role,
                    hospital_id: user.role === 'hospital_admin' ? user.hospital_id : null
                };

                // Redirect based on role
                switch (user.role) {
                    case 'hospital_admin':
                        return res.redirect('/admin-dashboard'); // Hospital admin dashboard
                    case 'admin':
                        return res.redirect('/admin/dashboard'); // Admin dashboard
                    default:
                        return res.redirect('/vaccines'); // Regular user
                }

            } else {
                // Incorrect password
                return res.render('login', { warning: 'Invalid Username or password. Please try again.' });
            }
        } else {
            // Username does not exist
            return res.render('login', { warning: 'Username not found. Please register or try again.' });
        }
    } catch (error) {
        console.error(error);
        res.send('Error during login');
    }
});

// Vaccines Route with search functionality
app.get('/vaccines', async (req, res) => {
    if (!req.session.user) {
        return res.redirect('/login');
    }

    const searchQuery = req.query.search ? req.query.search.toLowerCase() : null;
    const categoryFilter = req.query.category || null;  // Get category from query parameters
    let query = 'SELECT * FROM Vaccines';
    const values = [];

    // Modify the query to filter by category
    if (categoryFilter) {
        query += ' WHERE category = $1';
        values.push(categoryFilter);

        // If a search query is provided, append it to the category filter
        if (searchQuery) {
            query += ' AND LOWER(vaccine_name) LIKE $2';
            values.push(`%${searchQuery}%`);
        }
    } else if (searchQuery) {
        query += ' WHERE LOWER(vaccine_name) LIKE $1';
        values.push(`%${searchQuery}%`);
    }

    try {
        const result = await pool.query(query, values);
        res.render('vaccines', { vaccines: result.rows, category: categoryFilter });
    } catch (error) {
        console.error(error);
        res.send('Error fetching vaccines');
    }
});


// Add this route in app.js
app.get('/vaccines/:vaccineId/hospitals', async (req, res) => {
    const vaccineId = req.params.vaccineId;
    const cityFilter = req.query.city ? req.query.city.toLowerCase() : null;

    let query = `
        SELECT h.hospital_id, h.hospital_name, h.location, h.phone, h.image_url
        FROM Hospitals h 
        JOIN Vaccine_Inventory vi ON h.hospital_id = vi.hospital_id 
        WHERE vi.vaccine_id = $1
    `;
    const values = [vaccineId];

    if (cityFilter) {
        query += ` AND LOWER(h.location) LIKE '%' || $2 || '%'`;
        values.push(cityFilter);
    }

    try {
        const result = await pool.query(query, values);
        res.render('hospitals', { hospitals: result.rows, vaccineId });
    } catch (error) {
        console.error(error);
        res.send('Error fetching hospitals');
    }
});

// Update this route in app.js
app.get('/hospitals/:hospitalId/doctors', async (req, res) => {
    const hospitalId = req.params.hospitalId;

    const query = `
        SELECT d.doctor_id, d.doctor_name, d.specialization, d.image_url
        FROM Doctors d 
        WHERE d.hospital_id = $1
    `;

    try {
        const result = await pool.query(query, [hospitalId]);
        res.render('doctors', { doctors: result.rows, hospitalId });
    } catch (error) {
        console.error(error);
        res.send('Error fetching doctors');
    }
});

app.get('/hospitals/:hospitalId/doctors/:doctorId', async (req, res) => {
    const { hospitalId, doctorId } = req.params;

    // Optional: Validate hospitalId and doctorId
    if (!Number.isInteger(+hospitalId) || !Number.isInteger(+doctorId)) {
        return res.status(400).send('Invalid hospital or doctor ID.');
    }

    const query = `
    SELECT vi.vaccine_id, v.vaccine_name, vi.stock_quantity, vi.expiry_date, vi.price, v.image_url
    FROM Vaccine_Inventory vi 
    JOIN Vaccines v ON vi.vaccine_id = v.vaccine_id 
    WHERE vi.hospital_id = $1
`;


    try {
        // Fetch the vaccine inventory for the specified hospital
        const result = await pool.query(query, [hospitalId]);

        // Check if any vaccines were found
        if (result.rows.length === 0) {
            return res.status(404).send('No vaccines found for this hospital.');
        }

        // Render the inventory page with the fetched data
        res.render('inventory', { vaccines: result.rows, hospitalId, doctorId });
    } catch (error) {
        console.error('Error fetching inventory:', error);
        res.status(500).send('Error fetching inventory. Please try again later.');
    }
});


app.post('/create-checkout-session', async (req, res) => {
    // Check if the user is logged in
    if (!req.session.user) {
        return res.redirect('/login');
    }

    const { vaccine_id, hospital_id, doctor_id, appointment_date, appointment_time } = req.body;
    const userId = req.session.user.user_id;

    // Fetch the price of the vaccine from the inventory
    const priceQuery = `
        SELECT price FROM Vaccine_Inventory 
        WHERE vaccine_id = $1 AND hospital_id = $2
    `;

    try {
        const priceResult = await pool.query(priceQuery, [vaccine_id, hospital_id]);
        if (priceResult.rows.length === 0) {
            return res.status(400).send('Vaccine not found for this hospital.');
        }

        const price = priceResult.rows[0].price; // Assume price is in INR (Rupees)

        // Create a new Stripe Checkout session
        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            line_items: [{
                price_data: {
                    currency: 'inr', // Use INR for Indian Rupees
                    product_data: {
                        name: `Vaccine Appointment for ${vaccine_id}`,
                        description: `Appointment at Hospital ID: ${hospital_id} with Doctor ID: ${doctor_id}`,
                    },
                    unit_amount: price * 100, // Convert Rupees to paise (smallest unit)
                },
                quantity: 1,
            }],
            mode: 'payment',
            success_url: `${process.env.BASE_URL}/success?appointment_date=${encodeURIComponent(appointment_date)}&appointment_time=${encodeURIComponent(appointment_time)}&doctor_id=${encodeURIComponent(doctor_id)}&hospital_id=${encodeURIComponent(hospital_id)}&vaccine_id=${encodeURIComponent(vaccine_id)}`,
            cancel_url: 'http://localhost:3000/vaccines?payment_failed=true',
        });

        // Redirect to Stripe checkout session
        res.redirect(303, session.url);
    } catch (error) {
        console.error(error);
        res.status(500).send('Error creating checkout session');
    }
});


app.get('/success', async (req, res) => {
    const { appointment_date, appointment_time, doctor_id, hospital_id, vaccine_id } = req.query;

    // Validate the parameters here...

    const userId = req.session.user.user_id;

    // Create appointment and other necessary database updates
    const selectedDateTime = new Date(`${appointment_date}T${appointment_time}`);
    
    try {
        await pool.query('BEGIN');

        // Insert the appointment into the database
        const appointmentInsertQuery = `
            INSERT INTO Appointments (user_id, doctor_id, vaccine_id, hospital_id, appointment_date, status) 
            VALUES ($1, $2, $3, $4, $5, 'confirmed')
            RETURNING appointment_id;
        `;
        const appointmentResult = await pool.query(appointmentInsertQuery, [userId, doctor_id, vaccine_id, hospital_id, selectedDateTime]);
        const appointment_id = appointmentResult.rows[0].appointment_id;

        // Optionally update vaccine inventory here if needed...

        await pool.query('COMMIT');

        // Redirect to review page with appointment_id
        res.redirect(`/review?appointment_id=${appointment_id}`);
    } catch (error) {
        await pool.query('ROLLBACK');
        console.error(error);
        res.status(500).send('Error processing appointment');
    }
});

app.get('/payment-failure', (req, res) => {
    res.redirect('/vaccines');
});

// Add this route in app.js
app.get('/my-appointments', async (req, res) => {
    // Check if the user is logged in
    if (!req.session.user) {
        return res.redirect('/login');
    }

    const userId = req.session.user.user_id;

    const query = `
        SELECT a.appointment_id, v.vaccine_name, h.hospital_name, d.doctor_name, a.appointment_date, a.status, v.image_url AS vaccine_image_url
        FROM Appointments a
        JOIN Vaccines v ON a.vaccine_id = v.vaccine_id
        JOIN Hospitals h ON a.hospital_id = h.hospital_id
        JOIN Doctors d ON a.doctor_id = d.doctor_id
        WHERE a.user_id = $1
    `;

    try {
        const result = await pool.query(query, [userId]);
        res.render('my-appointments', { appointments: result.rows });
    } catch (error) {
        console.error(error);
        res.send('Error fetching appointments');
    }
});

app.post('/cancel-appointment/:appointmentId', async (req, res) => {
    if (!req.session.user) {
        return res.redirect('/login');
    }

    const appointmentId = req.params.appointmentId;

    try {
        const appointmentQuery = `
            SELECT vaccine_id, hospital_id FROM Appointments WHERE appointment_id = $1 AND user_id = $2
        `;
        const appointmentResult = await pool.query(appointmentQuery, [appointmentId, req.session.user.user_id]);

        if (appointmentResult.rows.length === 0) {
            return res.status(404).send('Appointment not found or you do not have permission to cancel it.');
        }

        const { vaccine_id, hospital_id } = appointmentResult.rows[0];

        // Delete the appointment
        await pool.query('DELETE FROM Appointments WHERE appointment_id = $1', [appointmentId]);

        // Update the inventory
        await pool.query(`
            UPDATE Vaccine_Inventory 
            SET stock_quantity = stock_quantity + 1 
            WHERE vaccine_id = $1 AND hospital_id = $2
        `, [vaccine_id, hospital_id]);

        // Send a notification
        const message = `Your appointment for vaccine ID ${vaccine_id} at hospital ID ${hospital_id} has been canceled.`;
        await pool.query(`
            INSERT INTO Notifications (user_id, message, status) 
            VALUES ($1, $2, 'sent')
        `, [req.session.user.user_id, message]);

        res.redirect('/my-appointments'); // Reload page after cancellation
    } catch (error) {
        console.error(error);
        res.status(500).send('Error canceling appointment: ' + error.message);
    }
});

// Reschedule Appointment Route
app.post('/reschedule-appointment', async (req, res) => {
    if (!req.session.user) {
        return res.redirect('/login');
    }

    const { appointment_id, new_appointment_date } = req.body;

    const today = new Date();
    const selectedDate = new Date(new_appointment_date);
    
    if (selectedDate < today) {
        return res.send('Cannot reschedule to a past date.');
    }

    try {
        const updateQuery = `
            UPDATE Appointments 
            SET appointment_date = $1, updated_at = CURRENT_TIMESTAMP 
            WHERE appointment_id = $2 AND user_id = $3
        `;
        await pool.query(updateQuery, [new_appointment_date, appointment_id, req.session.user.user_id]);

        res.redirect('/my-appointments'); // Reload page after reschedule
    } catch (error) {
        console.error(error);
        res.status(500).send('Error rescheduling appointment');
    }
});

// Route to display user notifications and mark them as read
app.get('/notifications', async (req, res) => {
    // Check if the user is logged in
    if (!req.session.user) {
        return res.redirect('/login');
    }

    const userId = req.session.user.user_id;

    // Query to fetch notifications for the logged-in user, ordered by most recent
    const notificationsQuery = `
        SELECT notification_id, message, sent_at, status 
        FROM Notifications 
        WHERE user_id = $1 
        ORDER BY sent_at DESC
    `;

    // Query to mark all notifications as 'read' or 'delivered'
    const markAsReadQuery = `
        UPDATE Notifications 
        SET status = 'delivered' 
        WHERE user_id = $1 AND status = 'pending'
    `;

    try {
        // Fetch notifications
        const result = await pool.query(notificationsQuery, [userId]);

        // Mark notifications as read
        await pool.query(markAsReadQuery, [userId]);

        res.render('notifications', { notifications: result.rows });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error fetching notifications');
    }
});

app.get('/review', async (req, res) => {
    const appointmentId = req.query.appointment_id;

    // Optionally fetch appointment details to show on the review page
    const query = `
        SELECT v.vaccine_name, h.hospital_name, d.doctor_id, d.doctor_name, a.hospital_id, a.appointment_date, a.status
        FROM Appointments a
        JOIN Vaccines v ON a.vaccine_id = v.vaccine_id
        JOIN Hospitals h ON a.hospital_id = h.hospital_id
        JOIN Doctors d ON a.doctor_id = d.doctor_id
        WHERE a.appointment_id = $1
    `;

    try {
        const result = await pool.query(query, [appointmentId]);
        if (result.rows.length === 0) {
            return res.status(404).send('Appointment not found');
        }
        res.render('review', { appointment: result.rows[0] });
    } catch (error) {
        console.error(error);
        res.send('Error fetching appointment details for review');
    }
});

// Add this route in app.js
app.post('/submit-review', ensureAuthenticated, async (req, res) => {
    const { rating, review_text, hospital_id, doctor_id } = req.body;
    const userId = req.session.user.user_id;

    // Validate hospital_id and doctor_id
    if (!hospital_id || !doctor_id) {
        return res.status(400).send('Invalid hospital or doctor information.');
    }

    const insertReviewQuery = `
        INSERT INTO Reviews (user_id, hospital_id, doctor_id, rating, review_text) 
        VALUES ($1, $2, $3, $4, $5)
    `;

    try {
        await pool.query(insertReviewQuery, [userId, parseInt(hospital_id), parseInt(doctor_id), rating, review_text]);
        res.redirect('/vaccines'); // Redirect to the vaccine list after submission
    } catch (error) {
        console.error(error);
        res.send('Error submitting review');
    }
});

app.get('/admin-dashboard', async (req, res) => {
    if (!req.session.user || req.session.user.role !== 'hospital_admin') {
        return res.redirect('/login');
    }

    res.render('admin-dashboard');
});

// View Inventory
app.get('/admin/inventory', async (req, res) => {
    if (!req.session.user || req.session.user.role !== 'hospital_admin') {
        return res.redirect('/login');
    }

    try {
        const hospitalQuery = `SELECT hospital_id FROM Hospitals WHERE hospital_admin_id = $1`;
        const hospitalResult = await pool.query(hospitalQuery, [req.session.user.user_id]);
        const hospitalId = hospitalResult.rows[0].hospital_id;

        const inventoryQuery = `
            SELECT V.vaccine_name, VI.stock_quantity, VI.expiry_date, VI.inventory_id 
            FROM Vaccine_Inventory VI 
            JOIN Vaccines V ON VI.vaccine_id = V.vaccine_id 
            WHERE VI.hospital_id = $1
        `;
        const inventoryResult = await pool.query(inventoryQuery, [hospitalId]);

        res.render('inventory_admin', { inventory: inventoryResult.rows });
    } catch (error) {
        console.error(error);
        res.send('Error fetching inventory');
    }
});

// Update Stock Quantity
app.post('/admin/inventory/update', async (req, res) => {
    if (!req.session.user || req.session.user.role !== 'hospital_admin') {
        return res.status(403).send('Unauthorized');
    }

    const { inventory_id, quantity } = req.body;

    try {
        const checkQuery = `
            SELECT VI.inventory_id 
            FROM Vaccine_Inventory VI
            JOIN Hospitals H ON VI.hospital_id = H.hospital_id
            WHERE VI.inventory_id = $1 AND H.hospital_admin_id = $2
        `;
        const checkResult = await pool.query(checkQuery, [inventory_id, req.session.user.user_id]);

        if (checkResult.rows.length === 0) {
            return res.status(403).send('You do not have permission to modify this inventory item.');
        }

        const updateQuery = `
            UPDATE Vaccine_Inventory 
            SET stock_quantity = $1, last_updated = NOW() 
            WHERE inventory_id = $2
        `;
        await pool.query(updateQuery, [quantity, inventory_id]);

        res.json({ success: true });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error updating inventory');
    }
});

app.post('/admin/inventory/add', upload.single('vaccine_image'), async (req, res) => {
    if (!req.session.user || req.session.user.role !== 'hospital_admin') {
        return res.redirect('/login');
    }

    const { vaccine_name, vaccine_type, stock_quantity, expiry_date, notes } = req.body;

    try {
        // Get the hospital ID associated with the logged-in admin
        const hospitalQuery = `SELECT hospital_id FROM Hospitals WHERE hospital_admin_id = $1`;
        const hospitalResult = await pool.query(hospitalQuery, [req.session.user.user_id]);

        // Check if the hospital exists
        if (hospitalResult.rows.length === 0) {
            return res.status(400).send('Hospital not found for the admin.');
        }

        const hospitalId = hospitalResult.rows[0].hospital_id;

        // Check if the vaccine exists in the Vaccines table
        let vaccineQuery = `SELECT vaccine_id FROM Vaccines WHERE vaccine_name = $1`;
        let vaccineResult = await pool.query(vaccineQuery, [vaccine_name]);

        let vaccineId;
        if (vaccineResult.rows.length === 0) {
            // If vaccine does not exist, insert it into the Vaccines table
            const insertVaccineQuery = `
                INSERT INTO Vaccines (vaccine_name, vaccine_type, created_at, updated_at)
                VALUES ($1, $2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                RETURNING vaccine_id
            `;
            const insertVaccineResult = await pool.query(insertVaccineQuery, [vaccine_name, vaccine_type]);
            vaccineId = insertVaccineResult.rows[0].vaccine_id;
        } else {
            // If vaccine exists, get the vaccine_id
            vaccineId = vaccineResult.rows[0].vaccine_id;
        }

        // Insert the new vaccine into the inventory
        const insertQuery = `
            INSERT INTO Vaccine_Inventory (hospital_id, vaccine_id, stock_quantity, expiry_date, notes)
            VALUES ($1, $2, $3, $4, $5)
        `;
        const vaccineImageFilename = req.file ? req.file.filename : null; // Get the uploaded file's filename (if needed)

        // Execute the insert query
        await pool.query(insertQuery, [hospitalId, vaccineId, stock_quantity, expiry_date, notes]);

        // Redirect to the inventory page after adding the vaccine
        res.redirect('/admin/inventory'); // This will show the updated inventory
    } catch (error) {
        console.error(error);
        res.status(500).send('Error adding new vaccine');
    }
});

// Remove Vaccine from Inventory
app.post('/admin/inventory/remove', async (req, res) => {
    if (!req.session.user || req.session.user.role !== 'hospital_admin') {
        return res.status(403).send('Unauthorized');
    }

    const { inventory_id } = req.body;

    try {
        const checkQuery = `
            SELECT VI.inventory_id 
            FROM Vaccine_Inventory VI
            JOIN Hospitals H ON VI.hospital_id = H.hospital_id
            WHERE VI.inventory_id = $1 AND H.hospital_admin_id = $2
        `;
        const checkResult = await pool.query(checkQuery, [inventory_id, req.session.user.user_id]);

        if (checkResult.rows.length === 0) {
            return res.status(403).send('You do not have permission to remove this inventory item.');
        }

        const deleteQuery = `DELETE FROM Vaccine_Inventory WHERE inventory_id = $1`;
        await pool.query(deleteQuery, [inventory_id]);

        res.json({ success: true });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error removing vaccine');
    }
});

// View Expired Vaccines
app.get('/admin/inventory/expired', async (req, res) => {
    if (!req.session.user || req.session.user.role !== 'hospital_admin') {
        return res.redirect('/login');
    }

    try {
        const hospitalQuery = `SELECT hospital_id FROM Hospitals WHERE hospital_admin_id = $1`;
        const hospitalResult = await pool.query(hospitalQuery, [req.session.user.user_id]);
        const hospitalId = hospitalResult.rows[0].hospital_id;

        const expiredQuery = `
            SELECT V.vaccine_name, VI.stock_quantity, VI.expiry_date 
            FROM Vaccine_Inventory VI 
            JOIN Vaccines V ON VI.vaccine_id = V.vaccine_id 
            WHERE VI.hospital_id = $1 AND VI.expiry_date < NOW()
        `;
        const expiredResult = await pool.query(expiredQuery, [hospitalId]);

        res.render('expired_vaccines', { expiredVaccines: expiredResult.rows });
    } catch (error) {
        console.error(error);
        res.send('Error fetching expired vaccines');
    }
});

// Get Reviews for Hospital
app.get('/admin/reviews', async (req, res) => {
    if (!req.session.user || req.session.user.role !== 'hospital_admin') {
        return res.status(403).send('Unauthorized');
    }

    try {
        const reviewsQuery = `
            SELECT R.review_id, U.username, R.rating, R.review_text, R.created_at 
            FROM Reviews R
            JOIN Users U ON R.user_id = U.user_id
            WHERE R.hospital_id = (SELECT hospital_id FROM Hospitals WHERE hospital_admin_id = $1)
            ORDER BY R.created_at DESC
        `;
        const reviewsResult = await pool.query(reviewsQuery, [req.session.user.user_id]);

        res.render('reviews_admin', { reviews: reviewsResult.rows });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error retrieving reviews');
    }
});

app.get('/profile', (req, res) => {
    if (!req.session.user) {
        return res.redirect('/login');
    }
    
    // Fetch the user's current profile data
    const userId = req.session.user.user_id;
    
    const query = 'SELECT * FROM Users WHERE user_id = $1';
    
    pool.query(query, [userId], (err, result) => {
        if (err) {
            return res.status(500).send('Error fetching profile');
        }
        
        const user = result.rows[0];
        res.render('profile', { user });
    });
});

app.post('/update-profile', async (req, res) => {
    if (!req.session.user) {
        return res.redirect('/login');
    }
    
    const { phone, address, emergency_contact } = req.body;
    const userId = req.session.user.user_id;

    const updateQuery = `
        UPDATE Users 
        SET phone = $1, address = $2, emergency_contact = $3, updated_at = NOW()
        WHERE user_id = $4
    `;

    try {
        await pool.query(updateQuery, [phone, address, emergency_contact, userId]);
        res.send('Profile updated successfully!');
    } catch (err) {
        console.error(err);
        res.status(500).send('Error updating profile');
    }
});

// Vaccine Awareness Information Page
app.get('/vaccine-info', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT v.*, vi.how_it_works, vi.side_effects, vi.precautions, vi.effectiveness 
            FROM Vaccines v
            JOIN vaccine_information vi ON v.vaccine_id = vi.vaccine_id
        `);
        const vaccines = result.rows;
        res.render('vaccine-info', { vaccines });
    } catch (error) {
        console.error(error);
        res.send('Error fetching vaccine information');
    }
});

// Route to add insurance details
app.post('/add-insurance', async (req, res) => {
    const { insurance_provider, policy_number, coverage_amount, expiry_date } = req.body;
    const userId = req.session.user.user_id;

    const insertQuery = `
        INSERT INTO Insurance_Details (user_id, insurance_provider, policy_number, coverage_amount, expiry_date)
        VALUES ($1, $2, $3, $4, $5)
    `;

    try {
        await pool.query(insertQuery, [userId, insurance_provider, policy_number, coverage_amount, expiry_date]);
        res.redirect('/insurance');
    } catch (error) {
        console.error(error);
        res.send('Error adding insurance details');
    }
});

// Route to get user's insurance details
app.get('/insurance', async (req, res) => {
    if (!req.session.user) {
        return res.redirect('/login');
    }

    const userId = req.session.user.user_id;
    const selectQuery = `SELECT * FROM Insurance_Details WHERE user_id = $1`;

    try {
        const result = await pool.query(selectQuery, [userId]);
        res.render('insurance', { insuranceDetails: result.rows }); // Ensure this is correct
    } catch (error) {
        console.error(error);
        res.send('Error fetching insurance details');
    }
});

// Get the insurance edit form
app.get('/insurance/edit/:id', async (req, res) => {
    const insuranceId = req.params.id;

    const selectQuery = `SELECT * FROM Insurance_Details WHERE insurance_id = $1`;
    try {
        const result = await pool.query(selectQuery, [insuranceId]);
        res.render('edit-insurance', { insurance: result.rows[0] });
    } catch (error) {
        console.error(error);
        res.send('Error fetching insurance details');
    }
});

// Handle the edit form submission
app.post('/insurance/edit/:id', async (req, res) => {
    const insuranceId = req.params.id;
    const { insurance_provider, policy_number, coverage_amount, expiry_date } = req.body;

    const updateQuery = `
        UPDATE Insurance_Details 
        SET insurance_provider = $1, policy_number = $2, coverage_amount = $3, expiry_date = $4 
        WHERE insurance_id = $5
    `;
    try {
        await pool.query(updateQuery, [insurance_provider, policy_number, coverage_amount, expiry_date, insuranceId]);
        res.redirect('/insurance');
    } catch (error) {
        console.error(error);
        res.send('Error updating insurance details');
    }
});

// Handle insurance deletion
app.get('/insurance/delete/:id', async (req, res) => {
    const insuranceId = req.params.id;
    
    const deleteQuery = `DELETE FROM Insurance_Details WHERE insurance_id = $1`;
    try {
        await pool.query(deleteQuery, [insuranceId]);
        res.redirect('/insurance');
    } catch (error) {
        console.error(error);
        res.send('Error deleting insurance details');
    }
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
