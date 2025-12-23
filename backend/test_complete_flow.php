<?php
// Complete authentication flow test
require_once 'db.php';
require_once 'token_utils.php';

echo "Complete Authentication Flow Test\n";
echo "=================================\n\n";

// 1. Test user registration
echo "1. Testing user registration...\n";
$registrationData = [
    'username' => 'testuser_' . time(),
    'email' => 'test' . time() . '@example.com',
    'password' => 'testpass123'
];

$ch = curl_init('http://localhost:8000/register.php');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($registrationData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$registerResponse = curl_exec($ch);
$registerHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Registration HTTP Code: $registerHttpCode\n";
echo "Registration Response: $registerResponse\n\n";

if ($registerHttpCode == 200) {
    $registerData = json_decode($registerResponse, true);
    if ($registerData['success']) {
        echo "✅ Registration successful\n";
        $userId = $registerData['user']['id'];
        $token = $registerData['auth_token'];
        
        // 2. Test profile update with the token
        echo "\n2. Testing profile update with token...\n";
        $updateData = [
            'username' => 'updated_' . time()
        ];
        
        $ch = curl_init('http://localhost:8000/update_user.php');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($updateData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $token
        ]);
        
        $updateResponse = curl_exec($ch);
        $updateHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "Update HTTP Code: $updateHttpCode\n";
        echo "Update Response: $updateResponse\n\n";
        
        if ($updateHttpCode == 200) {
            $updateResult = json_decode($updateResponse, true);
            if ($updateResult['success']) {
                echo "✅ Profile update successful!\n";
            } else {
                echo "❌ Profile update failed: " . ($updateResult['error'] ?? 'Unknown error') . "\n";
            }
        } else {
            echo "❌ Profile update request failed\n";
        }
        
    } else {
        echo "❌ Registration failed: " . ($registerData['error'] ?? 'Unknown error') . "\n";
    }
} else {
    echo "❌ Registration request failed\n";
}

echo "\nComplete test finished!\n";
?>
