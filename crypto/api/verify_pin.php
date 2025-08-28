<?php
session_start();
header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['pin'])) {
    echo json_encode(['success' => false, 'error' => 'PIN not provided']);
    exit;
}

$enteredPin = $data['pin'];

// Assume PIN stored in session at login (e.g., $_SESSION['pin'])
if (!isset($_SESSION['pin'])) {
    echo json_encode(['success' => false, 'error' => 'No PIN stored in session']);
    exit;
}

if ($enteredPin === $_SESSION['pin']) {
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'error' => 'Invalid PIN']);
}

