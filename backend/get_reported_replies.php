<?php
// Get Reported Replies - Fetch all replies with reports
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

// Get all replies that have reports
$sql = "
SELECT 
    r.id as report_id,
    r.reason,
    r.details,
    r.status,
    r.created_at as reported_at,
    rep.username as reporter_username,
    rep.id as reporter_id,
    a.id as reply_id,
    a.content as reply_content,
    a.created_at as reply_created_at,
    a.user_id as reply_author_id,
    author.username as reply_author_username,
    a.post_id,
    p.title as post_title,
    p.content as post_content
FROM reports r
JOIN users rep ON r.reporter_id = rep.id
JOIN answers a ON r.target_id = a.id AND r.report_type = 'reply'
JOIN users author ON a.user_id = author.id
LEFT JOIN posts p ON a.post_id = p.id
WHERE r.status = 'pending'
ORDER BY r.created_at DESC
";

$result = $conn->query($sql);

if ($result) {
    $reportedReplies = [];
    while ($row = $result->fetch_assoc()) {
        $reportedReplies[] = [
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
            'reply' => [
                'id' => $row['reply_id'],
                'content' => $row['reply_content'],
                'created_at' => $row['reply_created_at'],
                'author' => [
                    'id' => $row['reply_author_id'],
                    'username' => $row['reply_author_username']
                ]
            ],
            'post' => [
                'id' => $row['post_id'],
                'title' => $row['post_title'],
                'content' => $row['post_content']
            ]
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $reportedReplies,
        'count' => count($reportedReplies)
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to fetch reported replies: ' . $conn->error]);
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

