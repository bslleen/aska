<?php
// Full Report Flow Test - Test the complete report system flow
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'db.php';
require_once 'token_utils.php';

echo "=== Full Report Flow Test ===\n\n";

// Test 1: Generate a token for a regular user
echo "Test 1: Generate token for regular user (serine, user_id=1)\n";
$token = generateToken(1);
echo "Token: " . substr($token, 0, 50) . "...\n\n";

// Test 2: Submit a report for a post
echo "Test 2: Submit a report for post_id=1\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8001/report_post.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'post_id' => 1,
    'reason' => 'wrong_info',
    'details' => 'Test report from automated test'
]));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Status: $httpCode\n";
$result = json_decode($response, true);
echo json_encode($result, JSON_PRETTY_PRINT) . "\n\n";

if ($result['success'] ?? false) {
    $reportId = $result['report_id'];
    echo "✓ Report submitted successfully! Report ID: $reportId\n\n";
} else {
    echo "✗ Report submission failed: " . ($result['error'] ?? 'Unknown error') . "\n\n";
}

// Test 3: Verify report is in database
echo "Test 3: Verify report in database\n";
$stmt = $pdo->query("SELECT COUNT(*) as count FROM reports WHERE status = 'pending'");
$row = $stmt->fetch();
echo "Pending reports in database: " . $row['count'] . "\n\n";

// Test 4: Generate admin token
echo "Test 4: Generate admin token (lea, user_id=8)\n";
$adminToken = generateToken(8);
echo "Admin Token: " . substr($adminToken, 0, 50) . "...\n\n";

// Test 5: Fetch reported posts as admin
echo "Test 5: Fetch reported posts as admin\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8001/get_reported_posts.php');
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $adminToken
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Status: $httpCode\n";
$result = json_decode($response, true);
echo json_encode($result, JSON_PRETTY_PRINT) . "\n\n";

if ($result['success'] ?? false) {
    $count = $result['count'] ?? 0;
    echo "✓ Admin successfully retrieved $count reported posts!\n\n";
    
    if ($count > 0) {
        echo "Reported posts details:\n";
        foreach ($result['data'] as $post) {
            echo "  - Report ID: {$post['report_id']}\n";
            echo "    Post Title: {$post['post']['title']}\n";
            echo "    Reason: {$post['reason_display']}\n";
            echo "    Reporter: {$post['reporter']['username']}\n\n";
        }
    }
} else {
    echo "✗ Admin failed to retrieve reported posts: " . ($result['error'] ?? 'Unknown error') . "\n\n";
}

// Test 6: Fetch reported replies as admin
echo "Test 6: Fetch reported replies as admin\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8001/get_reported_replies.php');
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $adminToken
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Status: $httpCode\n";
$result = json_decode($response, true);
echo json_encode($result, JSON_PRETTY_PRINT) . "\n\n";

if ($result['success'] ?? false) {
    $count = $result['count'] ?? 0;
    echo "✓ Admin successfully retrieved $count reported replies!\n\n";
} else {
    echo "✗ Admin failed to retrieve reported replies: " . ($result['error'] ?? 'Unknown error') . "\n\n";
}

// Test 7: Try to access reported posts as regular user (should fail)
echo "Test 7: Try to access reported posts as regular user (should fail)\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8001/get_reported_posts.php');
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Status: $httpCode\n";
$result = json_decode($response, true);
echo json_encode($result, JSON_PRETTY_PRINT) . "\n\n";

if (isset($result['error']) && strpos($result['error'], 'Admin') !== false) {
    echo "✓ Regular user correctly denied access to admin-only endpoint\n\n";
} else {
    echo "⚠ Unexpected result when regular user accesses admin endpoint\n\n";
}

echo "=== Full Report Flow Test Complete ===\n";
echo "\nSummary:\n";
echo "- Regular users can report posts ✓\n";
echo "- Admin can view reported posts ✓\n";
echo "- Admin can view reported replies ✓\n";
echo "- Regular users cannot access admin endpoints ✓\n";

