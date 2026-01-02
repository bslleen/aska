<?php
// Delete Reported Content - Delete a reported post or reply (Admin only)
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

$targetId = $input['target_id'] ?? null;
$targetType = $input['target_type'] ?? null; // 'post' or 'reply'

if (!$targetId || !$targetType) {
    echo json_encode(['success' => false, 'error' => 'Target ID and type are required']);
    exit;
}

if (!in_array($targetType, ['post', 'reply'])) {
    echo json_encode(['success' => false, 'error' => 'Invalid target type']);
    exit;
}

$conn->begin_transaction();

try {
    if ($targetType === 'post') {
        // Delete the post and all associated replies and reports
        // First, get all replies for this post
        $repliesResult = $conn->query("SELECT id FROM answers WHERE post_id = $targetId");
        $replyIds = [];
        while ($row = $repliesResult->fetch_assoc()) {
            $replyIds[] = $row['id'];
        }
        
        // Delete reports for replies
        if (!empty($replyIds)) {
            $replyIdsStr = implode(',', $replyIds);
            $conn->query("DELETE FROM reports WHERE report_type = 'reply' AND target_id IN ($replyIdsStr)");
        }
        
        // Delete reports for this post
        $conn->query("DELETE FROM reports WHERE report_type = 'post' AND target_id = $targetId");
        
        // Delete replies
        $conn->query("DELETE FROM answers WHERE post_id = $targetId");
        
        // Delete the post
        $conn->query("DELETE FROM posts WHERE id = $targetId");
        
    } else {
        // Delete the reply and its reports
        // Delete reports for this reply
        $conn->query("DELETE FROM reports WHERE report_type = 'reply' AND target_id = $targetId");
        
        // Delete the reply
        $conn->query("DELETE FROM answers WHERE id = $targetId");
    }
    
    $conn->commit();
    
    echo json_encode([
        'success' => true,
        'message' => ucfirst($targetType) . ' deleted successfully',
        'deleted_id' => $targetId,
        'deleted_type' => $targetType
    ]);
    
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['success' => false, 'error' => 'Failed to delete ' . $targetType . ': ' . $e->getMessage()]);
}
?>

