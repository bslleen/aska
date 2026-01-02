<?php
// Get Reported Posts - Fetch all posts with reports
header('Content-Type: application/json');
require_once 'db.php';
require_once 'token_utils.php';
require_once 'admin_middleware.php';

// Verify admin access
$user = verifyAdminAccess();
if (isset($user['error'])) {
    echo json_encode(['success' => false, 'error' => $user['error']]);
    exit;
}

// Get all posts that have reports
$sql = "
SELECT 
    r.id as report_id,
    r.reason,
    r.details,
    r.status,
    r.created_at as reported_at,
    rep.username as reporter_username,
    rep.id as reporter_id,
    p.id as post_id,
    p.title as post_title,
    p.content as post_content,
    p.created_at as post_created_at,
    p.user_id as post_author_id,
    author.username as post_author_username,
    c.name as category_name
FROM reports r
JOIN users rep ON r.reporter_id = rep.id
JOIN posts p ON r.target_id = p.id AND r.report_type = 'post'
JOIN users author ON p.user_id = author.id
LEFT JOIN categories c ON p.category_id = c.id
WHERE r.status = 'pending'
ORDER BY r.created_at DESC
";

$result = $conn->query($sql);

if ($result) {
    $reportedPosts = [];
    while ($row = $result->fetch_assoc()) {
        $reportedPosts[] = [
            'report_id' => $row['report_id'],
            'reason' => $row['reason'],
            'reason_display' => getReasonDisplay($row['reason']),
            'details' => $row['details'],
            'status' => $row['status'],
            'reported_at' => $row['reported_at'],
            'reporter' => [
                'id' => $row['reporter_id'],
                'username' => $row['reporter_username']
            ],
            'post' => [
                'id' => $row['post_id'],
                'title' => $row['post_title'],
                'content' => $row['post_content'],
                'created_at' => $row['post_created_at'],
                'category' => $row['category_name'],
                'author' => [
                    'id' => $row['post_author_id'],
                    'username' => $row['post_author_username']
                ]
            ]
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $reportedPosts,
        'count' => count($reportedPosts)
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to fetch reported posts: ' . $conn->error]);
}

function getReasonDisplay($reason) {
    $reasons = [
        'wrong_info' => 'Wrong information',
        'not_related' => 'Not related to the question',
        'disrespectful' => 'Disrespectful',
        'other' => 'Other'
    ];
    return $reasons[$reason] ?? $reason;
}
?>

