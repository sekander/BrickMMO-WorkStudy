<?php
require_once __DIR__ . '/../config.php';

header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['error' => 'Invalid request method'], 405);
}

// Get input data
$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['username']) || !isset($data['password'])) {
    jsonResponse(['error' => 'Missing parameters'], 400);
}

$username = sanitizeInput($data['username']);
$password = $data['password'];


error_log("DEBUG: Username: $username");
error_log("DEBUG: Password: $password");

// Validate input
if (empty($username) || empty($password)) {
    jsonResponse(['error' => 'Username and password cannot be empty'], 400);
}

// Connect to database
$db = new mysqli(DB_HOST, DB_USERNAME, DB_PASSWORD, DB_NAME);

if ($db->connect_error) {
    jsonResponse(['error' => 'Database connection failed'], 500);
}

// Get user from database
$stmt = $db->prepare("SELECT id, username, password_hash, role, wallet_address, wallet_private_key_encrypted 
                     FROM users WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    // Simulate password verification to prevent timing attacks
    password_verify('dummy_password', '$2y$10$dummyhashdummyhashdummyhashdu');
    jsonResponse(['error' => 'Invalid username or password'], 401);
}

$user = $result->fetch_assoc();
$stmt->close();


// Verify password
if (!password_verify($password, $user['password_hash'])) {
    jsonResponse(['error' => 'Invalid username or password'], 401);
}

// Start session
session_start();
$_SESSION['user_id'] = $user['id'];
$_SESSION['username'] = $user['username'];
$_SESSION['role'] = $user['role'];
$_SESSION['wallet_address'] = $user['wallet_address'];

$usersJsonPath = __DIR__ . '/users.json';
if (file_exists($usersJsonPath)) {
    $json = file_get_contents($usersJsonPath);
    $usersList = json_decode($json, true);

    foreach ($usersList as $usr) {
        if (isset($usr['username']) && $usr['username'] === $username && isset($usr['pin'])) {
            $_SESSION['pin'] = $usr['pin'];  // ✅ Store in session
            break;
        }
    }
}

error_log("SESSION:\n" . print_r($_SESSION, true));

// Return user data (without sensitive information)
jsonResponse([
    'success' => true,
    'user' => [
        'username' => $user['username'],
        'role' => $user['role'],
        'walletAddress' => $user['wallet_address']
    ]
]);

