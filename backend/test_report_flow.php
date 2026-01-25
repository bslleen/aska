<?php
// Test Report Flow - Debug endpoint to test the complete report system
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'db.php';
require_once 'token_utils.php';

echo json_encode([
    'status' => 'Testing Report System',
    'timestamp' => date('Y-m-d H:i:s'),
], JSON_PRETTY_PRINT);

echo "\n\n";

// Test 1: Check database connection
echo "=== Test 1: Database Connection ===\n";
try {
    $pdo->query("SELECT 1");
    echo "✓ PDO connection: OK\n";
} catch (Exception $e) {
    echo "✗ PDO connection failed: " . $e->getMessage() . "\n";
}

try {
    $conn->query("SELECT 1");
    echo "✓ mysqli connection: OK\n";
} catch (Exception $e) {
    echo "✗ mysqli connection failed: " . $e->getMessage() . "\n";
}

// Test 2: Check reports table
echo "\n=== Test 2: Reports Table ===\n";
$result = $pdo->query("SHOW TABLES LIKE 'reports'");
if ($result->fetch()) {
    echo "✓ Reports table exists\n";
    
    // Count reports
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM reports");
    $row = $stmt->fetch();
    echo "  - Total reports: " . $row['count'] . "\n";
    
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM reports WHERE status = 'pending'");
    $row = $stmt->fetch();
    echo "  - Pending reports: " . $row['count'] . "\n";
} else {
    echo "✗ Reports table does not exist!\n";
    echo "  Run: php -f migrate_report_system.php\n";
}

// Test 3: Check if there are posts to report
echo "\n=== Test 3: Available Posts ===\n";
$result = $pdo->query("SELECT id, title, user_id FROM posts LIMIT 5");
$posts = $result->fetchAll();
if (count($posts) > 0) {
    echo "✓ Found " . count($posts) . " posts:\n";
    foreach ($posts as $post) {
        echo "  - ID: {$post['id']}, Title: " . substr($post['title'], 0, 30) . "...\n";
    }
} else {
    echo "⚠ No posts found\n";
}

// Test 4: Check if there are replies to report
echo "\n=== Test 4: Available Replies ===\n";
$result = $pdo->query("SELECT a.id, a.content, p.title as post_title FROM answers a JOIN posts p ON a.post_id = p.id LIMIT 5");
$replies = $result->fetchAll();
if (count($replies) > 0) {
    echo "✓ Found " . count($replies) . " replies:\n";
    foreach ($replies as $reply) {
        echo "  - ID: {$reply['id']}, Content: " . substr($reply['content'], 0, 30) . "...\n";
    }
} else {
    echo "⚠ No replies found\n";
}

// Test 5: Check admin users
echo "\n=== Test 5: Admin Users ===\n";
$stmt = $pdo->query("SELECT id, username, user_type FROM users WHERE user_type = 'admin'");
$admins = $stmt->fetchAll();
if (count($admins) > 0) {
    echo "✓ Found " . count($admins) . " admin(s):\n";
    foreach ($admins as $admin) {
        echo "  - ID: {$admin['id']}, Username: {$admin['username']}\n";
    }
} else {
    echo "⚠ No admin users found\n";
}

// Test 6: Check regular users
echo "\n=== Test 6: Regular Users ===\n";
$stmt = $pdo->query("SELECT id, username, user_type FROM users WHERE user_type != 'admin' LIMIT 5");
$users = $stmt->fetchAll();
if (count($users) > 0) {
    echo "✓ Found " . count($users) . " non-admin user(s):\n";
    foreach ($users as $user) {
        echo "  - ID: {$user['id']}, Username: {$user['username']}, Type: {$user['user_type']}\n";
    }
} else {
    echo "⚠ No regular users found\n";
}

// Test 7: Test token generation
echo "\n=== Test 7: Token Generation ===\n";
if (count($users) > 0) {
    $testUserId = $users[0]['id'];
    $token = generateToken($testUserId);
    echo "✓ Generated token for user $testUserId:\n";
    echo "  Token: " . substr($token, 0, 50) . "...\n";
    
    // Validate token
    $payload = validateToken($token);
    if ($payload && $payload['user_id'] == $testUserId) {
        echo "✓ Token validation: OK\n";
    } else {
        echo "✗ Token validation: FAILED\n";
    }
}

// Summary
echo "\n=== Summary ===\n";
echo "To test the report system:\n";
echo "1. Make sure the reports table exists (run migrate_report_system.php if needed)\n";
echo "2. Have a user report a post from the Flutter app\n";
echo "3. Check the Admin Dashboard -> Reported Content tab\n";
echo "4. Check server logs for any errors: tail -f backend/server.log\n";
echo "\nAPI Endpoints:\n";
echo "- Report a post: POST /report_post.php with {\"post_id\": 1, \"reason\": \"wrong_info\"}\n";
echo "- Get reported posts: GET /get_reported_posts.php (requires admin auth)\n";
echo "- Get reported replies: GET /get_reported_replies.php (requires admin auth)\n";

