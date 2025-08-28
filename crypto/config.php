<?php
// Database configuration
//define('DB_HOST', 'localhost');
define('DB_HOST', '192.168.2.87');
define('DB_USERNAME', 'fnky');
define('DB_PASSWORD', '454732');
define('DB_NAME', 'crypto_login');

// Encryption key for private keys (change this to a secure random string)
define('ENCRYPTION_KEY', 'your_32_byte_encryption_key_here');

// Helper function for JSON responses
function jsonResponse($data, $statusCode = 200) {
    header('Content-Type: application/json');
    http_response_code($statusCode);
    echo json_encode($data);
    exit;
}

// Input sanitization
function sanitizeInput($input) {
    return htmlspecialchars(strip_tags(trim($input)));
}

// Encryption functions
function encryptData($data) {
    $iv = openssl_random_pseudo_bytes(openssl_cipher_iv_length('aes-256-cbc'));
    $encrypted = openssl_encrypt($data, 'aes-256-cbc', ENCRYPTION_KEY, 0, $iv);
    return base64_encode($iv . $encrypted);
}

function decryptData($data) {
    $data = base64_decode($data);
    $ivLength = openssl_cipher_iv_length('aes-256-cbc');
    $iv = substr($data, 0, $ivLength);
    $encrypted = substr($data, $ivLength);
    return openssl_decrypt($encrypted, 'aes-256-cbc', ENCRYPTION_KEY, 0, $iv);
}
