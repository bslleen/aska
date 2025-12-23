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

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

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

$input = json_decode(file_get_contents('php://input'), true);

$username = isset($input['username']) ? trim($input['username']) : null;
$email = isset($input['email']) ? trim($input['email']) : null;
$full_name = isset($input['full_name']) ? trim($input['full_name']) : null;
$bio = isset($input['bio']) ? trim($input['bio']) : null;
$current_password = isset($input['current_password']) ? $input['current_password'] : null;
$new_password = isset($input['new_password']) ? $input['new_password'] : null;

// Validate input
if (empty($username) && empty($email) && empty($full_name) && empty($bio) && empty($new_password)) {
    echo json_encode(['error' => 'No fields to update']);
    exit;
}

try {
    // Start building the update query
    $updates = [];
    $params = [];
    
    // Update username if provided
    if (!empty($username)) {
        // Check if username is already taken by another user
        $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? AND id != ?");
        $stmt->execute([$username, $userId]);
        if ($stmt->fetch()) {
            echo json_encode(['error' => 'Username already taken']);
            exit;
        }
        $updates[] = "username = ?";
        $params[] = $username;
    }
    
    // Update email if provided
    if (!empty($email)) {
        // Validate email format
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            echo json_encode(['error' => 'Invalid email format']);
            exit;
        }
        
        // Check if email is already taken by another user
        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
        $stmt->execute([$email, $userId]);
        if ($stmt->fetch()) {
            echo json_encode(['error' => 'Email already taken']);
            exit;
        }
        $updates[] = "email = ?";
        $params[] = $email;
    }
    
    // Update full_name if provided
    if (!empty($full_name)) {
        $updates[] = "full_name = ?";
        $params[] = $full_name;
    }
    
    // Update bio if provided
    if (!empty($bio)) {
        $updates[] = "bio = ?";
        $params[] = $bio;
    }
    
    // Update password if provided
    if (!empty($new_password)) {
        // Verify current password
        if (empty($current_password)) {
            echo json_encode(['error' => 'Current password is required to set new password']);
            exit;
        }
        
        if (strlen($new_password) < 6) {
            echo json_encode(['error' => 'New password must be at least 6 characters']);
            exit;
        }
        
        // Get current password hash
        $stmt = $pdo->prepare("SELECT password_hash FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        
        if (!password_verify($current_password, $user['password_hash'])) {
            echo json_encode(['error' => 'Current password is incorrect']);
            exit;
        }
        
        $updates[] = "password_hash = ?";
        $params[] = password_hash($new_password, PASSWORD_DEFAULT);
    }
    
    if (empty($updates)) {
        echo json_encode(['error' => 'No valid fields to update']);
        exit;
    }
    
    // Add user ID to parameters
    $params[] = $userId;
    
    // Execute update
    $sql = "UPDATE users SET " . implode(", ", $updates) . " WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    
    // Get updated user data
    $stmt = $pdo->prepare("SELECT id, username, email, full_name, bio, created_at FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'User updated successfully',
        'user' => $user
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Update failed: '.$e->getMessage()]);
}
?>
