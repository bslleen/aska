<?php
// Delete Reported Content - Delete a reported post or reply (Admin only)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';
require_once 'token_utils.php';
require_once 'admin_middleware.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

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

// Verify admin access
$user = verifyAdminAccess();
if (isset($user['error'])) {
    echo json_encode(['success' => false, 'error' => $user['error']]);
    exit;
}

try {
    $pdo->beginTransaction();
    
    if ($targetType === 'post') {
        // Delete the post and all associated replies and reports
        // First, get all replies for this post using PDO
        $stmt = $pdo->prepare("SELECT id FROM answers WHERE post_id = ?");
        $stmt->execute([$targetId]);
        $replyIds = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        // Delete reports for replies
        if (!empty($replyIds)) {
            $placeholders = implode(',', array_fill(0, count($replyIds), '?'));
            $stmt = $pdo->prepare("DELETE FROM reports WHERE report_type = 'reply' AND target_id IN ($placeholders)");
            $stmt->execute($replyIds);
        }
        
        // Delete reports for this post
        $stmt = $pdo->prepare("DELETE FROM reports WHERE report_type = 'post' AND target_id = ?");
        $stmt->execute([$targetId]);
        
        // Delete votes on answers to this post
        $stmt = $pdo->prepare("DELETE FROM votes WHERE target_type = 'answer' AND target_id IN (SELECT id FROM answers WHERE post_id = ?)");
        $stmt->execute([$targetId]);
        
        // Delete votes on the post
        $stmt = $pdo->prepare("DELETE FROM votes WHERE target_type = 'post' AND target_id = ?");
        $stmt->execute([$targetId]);
        
        // Delete replies
        $stmt = $pdo->prepare("DELETE FROM answers WHERE post_id = ?");
        $stmt->execute([$targetId]);
        
        // Delete the post
        $stmt = $pdo->prepare("DELETE FROM posts WHERE id = ?");
        $stmt->execute([$targetId]);
        
    } else {
        // Delete the reply and its reports
        // Delete votes on this reply
        $stmt = $pdo->prepare("DELETE FROM votes WHERE target_type = 'answer' AND target_id = ?");
        $stmt->execute([$targetId]);
        
        // Delete reports for this reply
        $stmt = $pdo->prepare("DELETE FROM reports WHERE report_type = 'reply' AND target_id = ?");
        $stmt->execute([$targetId]);
        
        // Delete the reply
        $stmt = $pdo->prepare("DELETE FROM answers WHERE id = ?");
        $stmt->execute([$targetId]);
    }
    
    $pdo->commit();
    
    echo json_encode([
        'success' => true,
        'message' => ucfirst($targetType) . ' deleted successfully',
        'deleted_id' => $targetId,
        'deleted_type' => $targetType
    ]);
    
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo json_encode(['success' => false, 'error' => 'Failed to delete ' . $targetType . ': ' . $e->getMessage()]);
}
?>

