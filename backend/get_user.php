<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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

// Check if token is valid (with blacklist validation)
$payload = validateTokenWithBlacklist($token);
if (!$payload) {
    echo json_encode(['error' => 'User not authenticated']);
    exit;
}

$userId = $payload['user_id'];

try {
    // Get current user data
    $stmt = $pdo->prepare("SELECT id, username, email, full_name, bio, created_at FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    if (!$user) {
        echo json_encode(['error' => 'User not found']);
        exit;
    }
    
    echo json_encode([
        'success' => true,
        'user' => $user
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to get user data: '.$e->getMessage()]);
}
?>
