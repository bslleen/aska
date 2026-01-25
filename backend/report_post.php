<?php
// Report Post - Submit a report for a post
header('Content-Type: application/json');
require_once 'db.php';
require_once 'token_utils.php';

// Get authorization header
$headers = getallheaders();
$authToken = null;

foreach ($headers as $key => $value) {
    if (strtolower($key) === 'authorization') {
        if (preg_match('/Bearer\s+(.+)/i', $value, $matches)) {
            $authToken = trim($matches[1]);
        }
        break;
    }
}

if (!$authToken) {
    echo json_encode(['success' => false, 'error' => 'Authentication required']);
    exit;
}

// Verify token and get user
$user = validateToken($authToken);
if (!$user) {
    echo json_encode(['success' => false, 'error' => 'Invalid or expired token']);
    exit;
}

// Get input data
$input = json_decode(file_get_contents('php://input'), true);

$postId = $input['post_id'] ?? null;
$reason = $input['reason'] ?? null;
$details = $input['details'] ?? null;

if (!$postId || !$reason) {
    echo json_encode(['success' => false, 'error' => 'Post ID and reason are required']);
    exit;
}

// Validate reason
$validReasons = ['wrong_info', 'not_related', 'disrespectful', 'other'];
if (!in_array($reason, $validReasons)) {
    echo json_encode(['success' => false, 'error' => 'Invalid reason']);
    exit;
}

// Check if post exists (using PDO for consistency)
$checkPost = $pdo->prepare("SELECT id FROM posts WHERE id = ?");
$checkPost->execute([$postId]);
$postResult = $checkPost->fetch();

if (!$postResult) {
    echo json_encode(['success' => false, 'error' => 'Post not found']);
    exit;
}

// Check if user already reported this post (using PDO)
$checkExisting = $pdo->prepare("SELECT id FROM reports WHERE report_type = 'post' AND target_id = ? AND reporter_id = ?");
$checkExisting->execute([$postId, $user['user_id']]);
$existingResult = $checkExisting->fetch();

if ($existingResult) {
    echo json_encode(['success' => false, 'error' => 'You have already reported this post']);
    exit;
}

// Insert report (using PDO)
$stmt = $pdo->prepare("INSERT INTO reports (report_type, target_id, reporter_id, reason, details) VALUES ('post', ?, ?, ?, ?)");
$stmt->execute([$postId, $user['user_id'], $reason, $details]);

$reportId = $pdo->lastInsertId();

if ($reportId) {
    echo json_encode([
        'success' => true, 
        'message' => 'Post reported successfully',
        'report_id' => $reportId
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to report post']);
}

