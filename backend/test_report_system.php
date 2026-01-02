<?php
// Test Report System
header('Content-Type: application/json');
require_once 'db.php';
require_once 'token_utils.php';

echo "=== Testing Report System ===\n\n";

// Test 1: Check if reports table exists
echo "1. Checking if reports table exists...\n";
$result = $conn->query("SHOW TABLES LIKE 'reports'");
if ($result->num_rows > 0) {
    echo "   ✓ Reports table exists\n\n";
} else {
    echo "   ✗ Reports table does not exist. Run migrate_report_system.php first.\n\n";
    exit;
}

// Test 2: Check endpoints exist
echo "2. Checking endpoints...\n";
$endpoints = [
    'report_reply.php' => 'Report Reply',
    'report_post.php' => 'Report Post',
    'get_reported_posts.php' => 'Get Reported Posts',
    'get_reported_replies.php' => 'Get Reported Replies',
    'dismiss_report.php' => 'Dismiss Report',
    'delete_reported_content.php' => 'Delete Reported Content',
];

foreach ($endpoints as $file => $name) {
    if (file_exists($file)) {
        echo "   ✓ $name endpoint exists\n";
    } else {
        echo "   ✗ $name endpoint missing\n";
    }
}
echo "\n";

// Test 3: Check if there are any reports
echo "3. Checking for existing reports...\n";
$result = $conn->query("SELECT COUNT(*) as count FROM reports WHERE status = 'pending'");
$row = $result->fetch_assoc();
echo "   Pending reports: {$row['count']}\n\n";

// Test 4: Get sample data
echo "4. Sample data...\n";

// Get sample posts
$result = $conn->query("SELECT id, title FROM posts LIMIT 3");
echo "   Sample posts:\n";
while ($row = $result->fetch_assoc()) {
    echo "   - ID: {$row['id']}, Title: {$row['title']}\n";
}
echo "\n";

// Get sample replies
$result = $conn->query("SELECT a.id, a.content, p.title as post_title FROM answers a JOIN posts p ON a.post_id = p.id LIMIT 3");
echo "   Sample replies:\n";
while ($row = $result->fetch_assoc()) {
    echo "   - ID: {$row['id']}, Post: {$row['post_title']}\n";
}
echo "\n";

echo "=== Test Complete ===\n";
echo "\nTo use the report system:\n";
echo "1. Run http://localhost:8001/migrate_report_system.php to create the reports table\n";
echo "2. Users can report posts/replies from the home screen using the flag button\n";
echo "3. Admins can view and manage reports in the Admin Dashboard -> Reported Content tab\n";

