<?php
// Admin middleware functions
require_once 'token_utils.php';

// Global database connection
global $pdo;

/**
 * Verify admin access and return user payload or error array
 * 
 * @return array|false Returns user payload on success, or error array on failure
 */
function verifyAdminAccess() {
    global $pdo;
    
    if (!$pdo) {
        return ['error' => 'Database connection failed'];
    }
    
    // Get Authorization header
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (empty($authHeader)) {
        return ['error' => 'User not authenticated'];
    }
    
    // Extract Bearer token
    if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        $token = $matches[1];
    } else {
        return ['error' => 'Invalid authorization format'];
    }
    
    // Validate token
    $payload = validateTokenWithBlacklist($token);
    if (!$payload) {
        return ['error' => 'User not authenticated'];
    }
    
    $userId = $payload['user_id'];
    
    // Check if user is admin
    $stmt = $pdo->prepare("SELECT user_type FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    if (!$user || $user['user_type'] !== 'admin') {
        return ['error' => 'Access denied. Admin privileges required.'];
    }
    
    return $payload;
}

/**
 * Get admin user info
 * 
 * @return array|null Returns user array on success, null on failure
 */
function getAdminUser() {
    global $pdo;
    
    if (!$pdo) {
        return null;
    }
    
    // Get Authorization header
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (empty($authHeader)) {
        return null;
    }
    
    // Extract Bearer token
    if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        $token = $matches[1];
    } else {
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

