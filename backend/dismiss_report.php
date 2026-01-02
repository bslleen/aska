<?php
// Dismiss Report - Mark a report as dismissed (Admin only)
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

// Get input data
$input = json_decode(file_get_contents('php://input'), true);

$reportId = $input['report_id'] ?? null;
$reportType = $input['report_type'] ?? null; // 'post' or 'reply'

if (!$reportId) {
    echo json_encode(['success' => false, 'error' => 'Report ID is required']);
    exit;
}

// Validate report exists
$checkReport = $conn->prepare("SELECT id FROM reports WHERE id = ?");
$checkReport->bind_param("i", $reportId);
$checkReport->execute();
$reportResult = $checkReport->get_result();

if ($reportResult->num_rows === 0) {
    echo json_encode(['success' => false, 'error' => 'Report not found']);
    exit;
}

// Update report status to dismissed
$stmt = $conn->prepare("UPDATE reports SET status = 'dismissed', dismissed_by = ?, dismissed_at = NOW() WHERE id = ?");
$stmt->bind_param("ii", $user['id'], $reportId);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Report dismissed successfully',
        'report_id' => $reportId
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to dismiss report: ' . $conn->error]);
}
?>

