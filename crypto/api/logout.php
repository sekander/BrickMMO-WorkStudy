<?php
require_once __DIR__ . '/../config.php';

session_start();

// Unset all session variables
$_SESSION = array();

// Destroy the session
session_destroy();

jsonResponse(['success' => true, 'message' => 'Logged out successfully']);
