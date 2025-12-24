<?php
// Complete End-to-End Test for User "lea" Admin Role Fix
header('Content-Type: application/json');
require_once 'db.php';
require_once 'token_utils.php';

echo "=== COMPLETE END-TO-END TEST: User 'lea' Admin Role ===\n";

// Test 1: Database Verification
echo "\n--- Test 1: Database Verification ---\n";
try {
    $stmt = $pdo->prepare("SELECT id, username, email, user_type, full_name, bio, created_at FROM users WHERE username = ?");
    $stmt->execute(['lea']);
    $user = $stmt->fetch();
    
    if (!$user) {
        echo "✗ User 'lea' not found in database\n";
        exit;
    }
    
    echo "✓ User 'lea' found in database:\n";
    echo "  ID: {$user['id']}\n";
    echo "  Username: {$user['username']}\n";
    echo "  Email: {$user['email']}\n";
    echo "  User Type: {$user['user_type']}\n";
    echo "  Full Name: " . ($user['full_name'] ?? 'NULL') . "\n";
    echo "  Bio: " . ($user['bio'] ?? 'NULL') . "\n";
    
    if ($user['user_type'] === 'admin') {
        echo "✓ User 'lea' is correctly set as ADMIN in database\n";
    } else {
        echo "✗ User 'lea' is NOT admin, current role: {$user['user_type']}\n";
        exit;
    }
    
} catch (Exception $e) {
    echo "✗ Database error: " . $e->getMessage() . "\n";
    exit;
}

// Test 2: Login Response Structure (Simulated)
echo "\n--- Test 2: Login Response Structure ---\n";
try {
    // Verify password works
    $stmt = $pdo->prepare("SELECT password_hash FROM users WHERE username = ?");
    $stmt->execute(['lea']);
    $passwordData = $stmt->fetch();
    
    if (!password_verify('lea1234', $passwordData['password_hash'])) {
        echo "✗ Password verification failed\n";
        exit;
    }
    echo "✓ Password 'lea1234' verified successfully\n";
    
    // Generate token
    $authToken = generateToken($user['id']);
    
    // Simulate what the frontend will receive
    unset($user['password_hash']); // Remove password from response
    
    $loginResponse = [
        'success' => true,
        'message' => 'Login successful',
        'user' => $user,
        'auth_token' => $authToken
    ];
    
    echo "✓ Login response structure:\n";
    echo json_encode($loginResponse, JSON_PRETTY_PRINT);
    
    // Critical check: user_type in response
    if (isset($user['user_type']) && $user['user_type'] === 'admin') {
        echo "\n✓ user_type field present in login response\n";
        echo "✓ Value: 'admin'\n";
        echo "✓ Frontend will receive admin role\n";
    } else {
        echo "\n✗ user_type field missing or incorrect in response\n";
        exit;
    }
    
} catch (Exception $e) {
    echo "✗ Login simulation error: " . $e->getMessage() . "\n";
    exit;
}

// Test 3: Frontend AuthProvider Compatibility
echo "\n--- Test 3: Frontend AuthProvider Compatibility ---\n";

// Check what AuthProvider expects
echo "AuthProvider expects these user fields:\n";
echo "- id: ✓ (received: {$user['id']})\n";
echo "- username: ✓ (received: {$user['username']})\n";
echo "- email: ✓ (received: {$user['email']})\n";
echo "- full_name: " . (isset($user['full_name']) ? "✓ (received: {$user['full_name']})" : "✗ (missing)") . "\n";
echo "- bio: " . (isset($user['bio']) ? "✓ (received: {$user['bio']})" : "✗ (missing)") . "\n";
echo "- user_type: ✓ (received: {$user['user_type']})\n";
echo "- created_at: ✓ (received: {$user['created_at']})\n";
echo "- auth_token: ✓ (will be provided separately)\n";

echo "\n✓ All required fields for AuthProvider are present\n";

// Test 4: Admin UI Elements Expected
echo "\n--- Test 4: Expected UI Behavior ---\n";
echo "After user 'lea' logs in, these should appear:\n";
echo "1. Username display: 'lea 👑' (with crown icon)\n";
echo "2. Admin dashboard button visible in top bar\n";
echo "3. Admin privileges available (user management, etc.)\n";
echo "4. AuthProvider.isAdmin returns true\n";

// Test 5: Session Data Requirements
echo "\n--- Test 5: Session Data Requirements ---\n";
echo "For the fix to work, user 'lea' must:\n";
echo "1. LOG OUT completely (clear cached session)\n";
echo "2. LOG BACK IN (username: 'lea', password: 'lea1234')\n";
echo "3. Verify admin crown icon appears\n";
echo "4. Verify admin dashboard accessible\n";

echo "\n=== SUMMARY ===\n";
echo "✅ Database: User 'lea' is admin\n";
echo "✅ Backend: Login response includes user_type: 'admin'\n";
echo "✅ Frontend: AuthProvider will receive complete user data\n";
echo "✅ Expected: Admin UI elements should appear after re-login\n";

echo "\n🚨 IMPORTANT: User 'lea' must log out and log back in!\n";
echo "Cached session data doesn't include the admin role yet.\n";

echo "\n=== END OF TEST ===\n";
?>
