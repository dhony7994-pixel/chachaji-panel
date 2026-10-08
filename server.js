const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();

app.set('view engine', 'ejs');
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public'));
app.use(session({
    secret: 'chachaji-secret-key',
    resave: false,
    saveUninitialized: true
}));

// Mock Database / User Store
const users = [
    { username: process.env.ADMIN_USER, password: process.env.ADMIN_PASS, role: 'admin' }
];

// Routes
app.get('/', (req, res) => {
    if (!req.session.user) return res.redirect('/login');
    if (req.session.user.role === 'admin') {
        res.render('admin_dashboard', { user: req.session.user });
    } else {
        res.render('user_dashboard', { user: req.session.user });
    }
});

app.get('/login', (req, res) => {
    res.render('login', { error: null });
});

app.post('/login', (req, res) => {
    const { username, password } = req.body;
    const foundUser = users.find(u => u.username === username && u.password === password);
    
    if (foundUser) {
        req.session.user = foundUser;
        res.redirect('/');
    } else {
        res.render('login', { error: 'Invalid username or password' });
    }
});

app.get('/register', (req, res) => {
    res.render('register', { error: null });
});

app.post('/register', (req, res) => {
    const { username, password } = req.body;
    if (users.find(u => u.username === username)) {
        return res.render('register', { error: 'Username already exists' });
    }
    users.push({ username, password, role: 'user' });
    res.redirect('/login');
});

app.get('/logout', (req, res) => {
    req.session.destroy();
    res.redirect('/login');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Chachaji Panel running on port ${PORT}`);
});
