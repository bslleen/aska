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

$input = json_decode(file_get_contents('php://input'), true);

// Validate input
if (!isset($input['username']) && !isset($input['email'])) {
    echo json_encode(['error' => 'Username or email is required']);
    exit;
}

if (!isset($input['password'])) {
    echo json_encode(['error' => 'Password is required']);
    exit;
}

$username = isset($input['username']) ? trim($input['username']) : '';
$email = isset($input['email']) ? trim($input['email']) : '';
$password = $input['password'];

// Basic validation
if (empty($username) && empty($email)) {
    echo json_encode(['error' => 'Username or email is required']);
    exit;
}

if (empty($password)) {
    echo json_encode(['error' => 'Password is required']);
    exit;
}

try {
    // Find user by username or email
    if (!empty($username)) {
        $stmt = $pdo->prepare("SELECT id, username, email, password_hash, full_name, bio, created_at FROM users WHERE username = ?");
        $stmt->execute([$username]);
    } else {
        $stmt = $pdo->prepare("SELECT id, username, email, password_hash, full_name, bio, created_at FROM users WHERE email = ?");
        $stmt->execute([$email]);
    }
    
    $user = $stmt->fetch();
    
    if (!$user) {
        echo json_encode(['error' => 'Invalid username/email or password']);
        exit;
    }
    
    // Verify password
    if (!password_verify($password, $user['password_hash'])) {
        echo json_encode(['error' => 'Invalid username/email or password']);
        exit;
    }
    
    // Generate authentication token
    $authToken = generateToken($user['id']);
    
    // Remove password_hash from response
    unset($user['password_hash']);
    
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'user' => $user,
        'auth_token' => $authToken
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Login failed: '.$e->getMessage()]);
}
?>
