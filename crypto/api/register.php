<?php
require_once __DIR__ . '/../config.php';

header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['error' => 'Invalid request method'], 405);
}

$data = json_decode(file_get_contents('php://input'), true);

if (
    !$data ||
    !isset($data['username']) ||
    !isset($data['password']) ||
    !isset($data['pin']) ||
    !isset($data['walletAddress']) ||
    !isset($data['walletPrivateKey'])
) {
    jsonResponse(['error' => 'Missing parameters'], 400);
}

$username = sanitizeInput($data['username']);
$password = $data['password'];
$pin = $data['pin'];
$walletAddress = sanitizeInput($data['walletAddress']);
$walletPrivateKey = $data['walletPrivateKey'];

// Validate inputs
if (strlen($username) < 3) {
    jsonResponse(['error' => 'Username must be at least 3 characters'], 400);
}

if (strlen($password) < 8) {
    jsonResponse(['error' => 'Password must be at least 8 characters'], 400);
}

if (!preg_match('/^\d{4}$/', $pin)) {
    jsonResponse(['error' => 'PIN must be exactly 4 digits'], 400);
}

// Connect to database
$db = new mysqli(DB_HOST, DB_USERNAME, DB_PASSWORD, DB_NAME);

if ($db->connect_error) {
    jsonResponse(['error' => 'Database connection failed'], 500);
}

// Check if username exists
$stmt = $db->prepare("SELECT id FROM users WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    jsonResponse(['error' => 'Username already exists'], 409);
}
$stmt->close();

// Hash password
$passwordHash = password_hash($password, PASSWORD_BCRYPT);

// Encrypt private key
$encryptedPrivateKey = encryptData($walletPrivateKey);

// Insert new user into DB
$stmt = $db->prepare("INSERT INTO users (username, password_hash, wallet_address, wallet_private_key_encrypted, role) 
                     VALUES (?, ?, ?, ?, 'user')");
$stmt->bind_param("ssss", $username, $passwordHash, $walletAddress, $encryptedPrivateKey);

if ($stmt->execute()) {
    $stmt->close();
    $db->close();

    // --- Append to users.json ---
    //$usersFile = __DIR__ . '/../users.json';
    $usersFile = __DIR__ . '/users.json';

    // Load existing users or create a new array
    $users = [];
    if (file_exists($usersFile)) {
        $json = file_get_contents($usersFile);
        $users = json_decode($json, true);
        if (!is_array($users)) {
            $users = [];
        }
    }

    // Add new user to JSON
    $users[] = [
        'username' => $username,
        //'password' => $password, // Note: plaintext; you may want to hash or avoid saving this
        'role' => 'user',
        'wallet' => $walletAddress,
        'privateKey' => $walletPrivateKey,
        'pin' => $pin // Not secure — remove for production
    ];

    // Save back to users.json
    file_put_contents($usersFile, json_encode($users, JSON_PRETTY_PRINT));

    jsonResponse(['success' => true]);
} else {
    $stmt->close();
    $db->close();
    jsonResponse(['error' => 'Registration failed'], 500);
}

