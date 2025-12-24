<?php
// Test login endpoint with user_type fix
header('Content-Type: application/json');
require_once 'db.php';
require_once 'token_utils.php';

echo "=== Testing Login with user_type Fix ===\n";

// Test login as lea (admin user)
$testData = [
    'username' => 'lea',
    'password' => 'lea1234'
];

echo "\n--- Testing login for user 'lea' ---\n";

try {
    // Make the same query that login.php would use
    $stmt = $pdo->prepare("SELECT id, username, email, password_hash, full_name, bio, user_type, created_at FROM users WHERE username = ?");
    $stmt->execute(['lea']);
    $user = $stmt->fetch();
    
    if (!$user) {
        echo "✗ User 'lea' not found\n";
        exit;
    }
    
    echo "✓ Found user 'lea':\n";
    echo "  ID: {$user['id']}\n";
    echo "  Username: {$user['username']}\n";
    echo "  Email: {$user['email']}\n";
    echo "  User Type: {$user['user_type']}\n";
    echo "  Full Name: " . ($user['full_name'] ?? 'NULL') . "\n";
    echo "  Bio: " . ($user['bio'] ?? 'NULL') . "\n";
    echo "  Created: {$user['created_at']}\n";
    
    // Verify password
    if (password_verify('lea1234', $user['password_hash'])) {
        echo "✓ Password verification successful\n";
    } else {
        echo "✗ Password verification failed\n";
    }
    
    // Test what the login response would look like
    $authToken = generateToken($user['id']);
    unset($user['password_hash']);
    
    echo "\n--- Login Response Structure ---\n";
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'user' => $user,
        'auth_token' => substr($authToken, 0, 20) . '...'
    ], JSON_PRETTY_PRINT);
    
    // Verify user_type is in the response
    if (isset($user['user_type'])) {
        echo "\n✓ user_type field is present in response\n";
        echo "✓ User role: {$user['user_type']}\n";
        
        if ($user['user_type'] === 'admin') {
            echo "✓ User 'lea' will be recognized as admin in frontend\n";
        }
    } else {
        echo "\n✗ user_type field is missing from response\n";
    }
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
}

echo "\n=== Test Complete ===\n";
echo "\nExpected frontend behavior after login:\n";
echo "1. AuthProvider will receive user data with user_type='admin'\n";
echo "2. isAdmin getter will return true\n";
echo "3. Admin crown icon (👑) will appear in UI\n";
echo "4. Admin dashboard will be accessible\n";
?>
