<?php
// Test token system
require_once 'token_utils.php';

echo "Testing Token System\n";
echo "===================\n\n";

// Test token generation
echo "1. Testing token generation...\n";
$testUserId = 123;
$token = generateToken($testUserId);
echo "Generated token: $token\n";

// Test token validation
echo "\n2. Testing token validation...\n";
$userId = getUserIdFromToken($token);
echo "Extracted user ID: $userId\n";
echo "Token valid: " . ($userId !== null ? "YES" : "NO") . "\n";

// Test invalid token
echo "\n3. Testing invalid token...\n";
$invalidUserId = getUserIdFromToken("invalid.token");
echo "Invalid token validation: " . ($invalidUserId === null ? "PASS" : "FAIL") . "\n";

// Test expired token (simulate)
echo "\n4. Testing expired token...\n";
$expiredPayload = [
    'user_id' => 123,
    'iat' => time() - (8 * 24 * 60 * 60), // 8 days ago
    'exp' => time() - (7 * 24 * 60 * 60), // 7 days ago (expired)
];
$expiredTokenData = base64_encode(json_encode($expiredPayload));
$expiredSignature = hash_hmac('sha256', $expiredTokenData, 'your-secret-key-here');
$expiredToken = $expiredTokenData . '.' . $expiredSignature;
$expiredUserId = getUserIdFromToken($expiredToken);
echo "Expired token validation: " . ($expiredUserId === null ? "PASS" : "FAIL") . "\n";

echo "\nToken system test complete!\n";
?>
