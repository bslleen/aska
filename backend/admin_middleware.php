<?php
// Admin middleware functions
require_once 'token_utils.php';

// Global database connection
global $pdo;

/**
 * Check if current user is admin
 */
function checkAdminAccess($token) {
    global $pdo;
    
    if (!$pdo) {
        echo json_encode(['error' => 'Database connection failed']);
        return false;
    }
    
    // Validate token
    $payload = validateTokenWithBlacklist($token);
    if (!$payload) {
        echo json_encode(['error' => 'User not authenticated']);
        return false;
    }
    
    $userId = $payload['user_id'];
    
    // Check if user is admin
    $stmt = $pdo->prepare("SELECT user_type FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    if (!$user || $user['user_type'] !== 'admin') {
        echo json_encode(['error' => 'Access denied. Admin privileges required.']);
        return false;
    }
    
    return $payload;
}

/**
 * Get admin user info
 */
function getAdminUser($token) {
    global $pdo;
    
    if (!$pdo) {
        return null;
    }
    
    $payload = validateTokenWithBlacklist($token);
    if (!$payload) {
        return null;
    }
    
    $userId = $payload['user_id'];
    $stmt = $pdo->prepare("SELECT id, username, email, full_name, bio, user_type, created_at FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    return $user;
}
?>
