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
if (!isset($input['username']) || !isset($input['email']) || !isset($input['password'])) {
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

$username = trim($input['username']);
$email = trim($input['email']);
$password = $input['password'];
$full_name = isset($input['full_name']) ? trim($input['full_name']) : '';
$bio = isset($input['bio']) ? trim($input['bio']) : '';

// Basic validation
if (empty($username) || empty($email) || empty($password)) {
    echo json_encode(['error' => 'Username, email, and password are required']);
    exit;
}

if (strlen($password) < 6) {
    echo json_encode(['error' => 'Password must be at least 6 characters']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['error' => 'Invalid email format']);
    exit;
}

try {
    // Check if username or email already exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
    $stmt->execute([$username, $email]);
    
    if ($stmt->fetch()) {
        echo json_encode(['error' => 'Username or email already exists']);
        exit;
    }
    
    // Hash the password
    $password_hash = password_hash($password, PASSWORD_DEFAULT);
    
    // Insert new user
    $stmt = $pdo->prepare("INSERT INTO users (username, email, password_hash, full_name, bio) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$username, $email, $password_hash, $full_name, $bio]);
    
    $user_id = $pdo->lastInsertId();
    
    // Get the created user (without password)
    $stmt = $pdo->prepare("SELECT id, username, email, full_name, bio, created_at FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();
    
    // Generate authentication token for the new user
    $authToken = generateToken($user_id);
    
    echo json_encode([
        'success' => true,
        'message' => 'User registered successfully',
        'user' => $user,
        'auth_token' => $authToken
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Registration failed: '.$e->getMessage()]);
}
?>
