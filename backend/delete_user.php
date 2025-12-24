<?php
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
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Get authorization header
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = null;

if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}

// Check admin access
$adminPayload = checkAdminAccess($token);
if (!$adminPayload) {
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

// Validate input
if (!isset($input['user_id'])) {
    echo json_encode(['error' => 'user_id is required']);
    exit;
}

$targetUserId = $input['user_id'];
$adminUserId = $adminPayload['user_id'];

// Prevent admin from deleting themselves
if ($targetUserId == $adminUserId) {
    echo json_encode(['error' => 'You cannot delete your own account']);
    exit;
}

try {
    // Check if target user exists
    $stmt = $pdo->prepare("SELECT id, username, email, user_type FROM users WHERE id = ?");
    $stmt->execute([$targetUserId]);
    $targetUser = $stmt->fetch();
    
    if (!$targetUser) {
        echo json_encode(['error' => 'User not found']);
        exit;
    }
    
    // Check if target user is also admin (additional protection)
    if ($targetUser['user_type'] === 'admin') {
        echo json_encode(['error' => 'Cannot delete another admin user']);
        exit;
    }
    
    // Get admin user info for logging
    $stmt = $pdo->prepare("SELECT username FROM users WHERE id = ?");
    $stmt->execute([$adminUserId]);
    $adminUser = $stmt->fetch();
    
    // Start transaction for data integrity
    $pdo->beginTransaction();
    
    // Delete user's answers first (due to foreign key constraints)
    $stmt = $pdo->prepare("DELETE FROM answers WHERE user_id = ?");
    $stmt->execute([$targetUserId]);
    $answersDeleted = $stmt->rowCount();
    
    // Delete user's posts (due to foreign key constraints)
    $stmt = $pdo->prepare("DELETE FROM posts WHERE user_id = ?");
    $stmt->execute([$targetUserId]);
    $postsDeleted = $stmt->rowCount();
    
    // Delete user's votes
    $stmt = $pdo->prepare("DELETE FROM votes WHERE user_id = ?");
    $stmt->execute([$targetUserId]);
    $votesDeleted = $stmt->rowCount();
    
    // Finally delete the user
    $stmt = $pdo->prepare("DELETE FROM users WHERE id = ?");
    $stmt->execute([$targetUserId]);
    
    if ($stmt->rowCount() === 0) {
        $pdo->rollBack();
        echo json_encode(['error' => 'Failed to delete user']);
        exit;
    }
    
    // Commit the transaction
    $pdo->commit();
    
    echo json_encode([
        'success' => true,
        'message' => "User '{$targetUser['username']}' deleted successfully",
        'deleted_user' => [
            'id' => $targetUser['id'],
            'username' => $targetUser['username'],
            'email' => $targetUser['email'],
            'user_type' => $targetUser['user_type']
        ],
        'cleanup_stats' => [
            'posts_deleted' => $postsDeleted,
            'answers_deleted' => $answersDeleted,
            'votes_deleted' => $votesDeleted
        ],
        'deleted_by' => [
            'admin_id' => $adminUserId,
            'admin_username' => $adminUser['username'],
            'timestamp' => date('Y-m-d H:i:s')
        ]
    ]);
    
} catch (PDOException $e) {
    // Rollback on error
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo json_encode(['error' => 'Failed to delete user: '.$e->getMessage()]);
}
?>
