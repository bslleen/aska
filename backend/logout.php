<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';
require_once 'token_utils.php';

// Get authorization header
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = null;

if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}

// Check if token is valid
$userId = getUserIdFromToken($token);
if (!$userId) {
    echo json_encode(['error' => 'User not authenticated']);
    exit;
}

// Blacklist the token to invalidate it
$blacklisted = blacklistToken($token, $userId);
if (!$blacklisted) {
    echo json_encode(['error' => 'Failed to logout properly']);
    exit;
}

// Clean up any old expired tokens (optional maintenance)
cleanupExpiredTokens();

echo json_encode([
    'success' => true,
    'message' => 'Logout successful'
]);
?>
