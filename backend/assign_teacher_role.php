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

$adminUserId = $payload['user_id'];

// Get the requesting user's info to check if they're admin (you can modify this logic as needed)
$stmt = $pdo->prepare("SELECT user_type FROM users WHERE id = ?");
$stmt->execute([$adminUserId]);
$adminUser = $stmt->fetch();

if (!$adminUser || !in_array($adminUser['user_type'], ['teacher', 'admin'])) {
    echo json_encode(['error' => 'Access denied. Only teachers and admins can assign roles.']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

// Validate input
if (!isset($input['user_id']) || !isset($input['user_type'])) {
    echo json_encode(['error' => 'user_id and user_type are required']);
    exit;
}

$targetUserId = $input['user_id'];
$newUserType = $input['user_type'];

// Validate user_type - admins can assign any role, teachers can only assign student/teacher
if ($adminUser['user_type'] === 'admin') {
    // Admin can assign any role
    if (!in_array($newUserType, ['student', 'teacher', 'admin'])) {
        echo json_encode(['error' => 'Invalid user_type. Admin can assign "student", "teacher", or "admin"']);
        exit;
    }
} else {
    // Teacher can only assign student/teacher
    if (!in_array($newUserType, ['student', 'teacher'])) {
        echo json_encode(['error' => 'Invalid user_type. Teacher can only assign "student" or "teacher"']);
        exit;
    }
}

try {
    // Check if target user exists
    $stmt = $pdo->prepare("SELECT id, username, email, user_type FROM users WHERE id = ?");
    $stmt->execute([$targetUserId]);
    $targetUser = $stmt->fetch();
    
    if (!$targetUser) {
        echo json_encode(['error' => 'Target user not found']);
        exit;
    }
    
    // Update user type
    $stmt = $pdo->prepare("UPDATE users SET user_type = ? WHERE id = ?");
    $stmt->execute([$newUserType, $targetUserId]);
    
    // Get updated user data
    $stmt = $pdo->prepare("SELECT id, username, email, full_name, bio, user_type, created_at FROM users WHERE id = ?");
    $stmt->execute([$targetUserId]);
    $updatedUser = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => "User role updated to {$newUserType} successfully",
        'user' => $updatedUser
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Role assignment failed: '.$e->getMessage()]);
}
?>
