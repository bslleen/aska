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
$user = verifyToken($authToken);
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

// Check if reply exists
$checkReply = $conn->prepare("SELECT id FROM answers WHERE id = ?");
$checkReply->bind_param("i", $replyId);
$checkReply->execute();
$replyResult = $checkReply->get_result();

if ($replyResult->num_rows === 0) {
    echo json_encode(['success' => false, 'error' => 'Reply not found']);
    exit;
}
$replyData = $replyResult->fetch_assoc();

// Check if user already reported this reply
$checkExisting = $conn->prepare("SELECT id FROM reports WHERE report_type = 'reply' AND target_id = ? AND reporter_id = ?");
$checkExisting->bind_param("ii", $replyId, $user['id']);
$checkExisting->execute();
$existingResult = $checkExisting->get_result();

if ($existingResult->num_rows > 0) {
    echo json_encode(['success' => false, 'error' => 'You have already reported this reply']);
    exit;
}

// Insert report
$stmt = $conn->prepare("INSERT INTO reports (report_type, target_id, reporter_id, reason, details) VALUES ('reply', ?, ?, ?, ?)");
$stmt->bind_param("iiis", $replyId, $user['id'], $reason, $details);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true, 
        'message' => 'Reply reported successfully',
        'report_id' => $conn->insert_id
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to report reply: ' . $conn->error]);
}

