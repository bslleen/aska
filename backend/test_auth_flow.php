<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';
require_once 'token_utils.php';

echo "=== AUTHENTICATION FLOW TEST ===\n\n";

// Test 1: Generate a test token
echo "1. Testing token generation...\n";
$testUserId = 1; // Assuming user ID 1 exists
$token = generateToken($testUserId);
echo "Generated token: " . $token . "\n\n";

// Test 2: Validate the token
echo "2. Testing token validation...\n";
$payload = validateToken($token);
if ($payload) {
    echo "Token validation: SUCCESS\n";
    echo "User ID from token: " . $payload['user_id'] . "\n";
    echo "Token expiration: " . date('Y-m-d H:i:s', $payload['exp']) . "\n";
} else {
    echo "Token validation: FAILED\n";
}
echo "\n";

// Test 3: Test with invalid token
echo "3. Testing invalid token...\n";
$invalidPayload = validateToken("invalid.token.here");
if ($invalidPayload) {
    echo "Invalid token validation: FAILED (should return false)\n";
} else {
    echo "Invalid token validation: SUCCESS (correctly returned false)\n";
}
echo "\n";

// Test 4: Test blacklist functionality
echo "4. Testing token blacklist...\n";

// First, check if token is blacklisted (should be false)
$isBlacklisted = isTokenBlacklisted($token);
echo "Token blacklisted before: " . ($isBlacklisted ? "YES" : "NO") . "\n";

// Add token to blacklist
$blacklisted = blacklistToken($token, $testUserId);
echo "Token added to blacklist: " . ($blacklisted ? "SUCCESS" : "FAILED") . "\n";

// Check if token is now blacklisted
$isBlacklisted = isTokenBlacklisted($token);
echo "Token blacklisted after: " . ($isBlacklisted ? "YES" : "NO") . "\n";

// Test validate with blacklist
$payloadWithBlacklist = validateTokenWithBlacklist($token);
echo "Token validation with blacklist: " . ($payloadWithBlacklist ? "FAILED (should be false)" : "SUCCESS") . "\n";
echo "\n";

// Test 5: Test actual API endpoint authentication
echo "5. Testing actual endpoint authentication...\n";

// Simulate what the frontend sends
$headers = getallheaders();
echo "Received headers: " . json_encode($headers) . "\n";

$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
echo "Authorization header: " . $authHeader . "\n";

$token = null;
if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
    echo "Extracted token: " . $token . "\n";
} else {
    echo "No Bearer token found in header\n";
}

// Validate the token
$payload = validateTokenWithBlacklist($token);
if ($payload) {
    echo "API authentication: SUCCESS\n";
    echo "Authenticated user ID: " . $payload['user_id'] . "\n";
} else {
    echo "API authentication: FAILED\n";
    echo "This would result in 'User not authenticated' error\n";
}

echo "\n=== TEST COMPLETE ===\n";
?>
