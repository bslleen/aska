<?php
// Report Reply - Submit a report for a reply
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

$replyId = $input['reply_id'] ?? null;
$reason = $input['reason'] ?? null;
$details = $input['details'] ?? null;

if (!$replyId || !$reason) {
    echo json_encode(['success' => false, 'error' => 'Reply ID and reason are required']);
    exit;
}

// Validate reason
$validReasons = ['wrong_info', 'not_related', 'disrespectful', 'other'];
if (!in_array($reason, $validReasons)) {
    echo json_encode(['success' => false, 'error' => 'Invalid reason']);
    exit;
}

// Check if reply exists (using PDO for consistency)
$checkReply = $pdo->prepare("SELECT id FROM answers WHERE id = ?");
$checkReply->execute([$replyId]);
$replyResult = $checkReply->fetch();

if (!$replyResult) {
    echo json_encode(['success' => false, 'error' => 'Reply not found']);
    exit;
}

// Check if user already reported this reply (using PDO)
$checkExisting = $pdo->prepare("SELECT id FROM reports WHERE report_type = 'reply' AND target_id = ? AND reporter_id = ?");
$checkExisting->execute([$replyId, $user['user_id']]);
$existingResult = $checkExisting->fetch();

if ($existingResult) {
    echo json_encode(['success' => false, 'error' => 'You have already reported this reply']);
    exit;
}

// Insert report (using PDO)
$stmt = $pdo->prepare("INSERT INTO reports (report_type, target_id, reporter_id, reason, details) VALUES ('reply', ?, ?, ?, ?)");
$stmt->execute([$replyId, $user['user_id'], $reason, $details]);

$reportId = $pdo->lastInsertId();

if ($reportId) {
    echo json_encode([
        'success' => true, 
        'message' => 'Reply reported successfully',
        'report_id' => $reportId
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to report reply']);
}

