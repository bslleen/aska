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
if (!isset($input['post_id'])) {
    echo json_encode(['error' => 'post_id is required']);
    exit;
}

$postId = $input['post_id'];
$adminUserId = $adminPayload['user_id'];

try {
    // Get post information before deletion
    $stmt = $pdo->prepare("
        SELECT 
            p.id, 
            p.title, 
            p.content, 
            u.username as author_username,
            u.id as author_id,
            c.name as category_name,
            p.created_at
        FROM posts p
        JOIN users u ON p.user_id = u.id
        JOIN categories c ON p.category_id = c.id
        WHERE p.id = ?
    ");
    $stmt->execute([$postId]);
    $post = $stmt->fetch();
    
    if (!$post) {
        echo json_encode(['error' => 'Post not found']);
        exit;
    }
    
    // Get admin user info for logging
    $stmt = $pdo->prepare("SELECT username FROM users WHERE id = ?");
    $stmt->execute([$adminUserId]);
    $adminUser = $stmt->fetch();
    
    // Start transaction for data integrity
    $pdo->beginTransaction();
    
    // Delete all answers to this post first
    $stmt = $pdo->prepare("DELETE FROM answers WHERE post_id = ?");
    $stmt->execute([$postId]);
    $answersDeleted = $stmt->rowCount();
    
    // Delete all votes on this post
    $stmt = $pdo->prepare("DELETE FROM votes WHERE target_type = 'post' AND target_id = ?");
    $stmt->execute([$postId]);
    $postVotesDeleted = $stmt->rowCount();
    
    // Delete all votes on answers to this post
    $stmt = $pdo->prepare("
        DELETE FROM votes 
        WHERE target_type = 'answer' 
        AND target_id IN (SELECT id FROM answers WHERE post_id = ?)
    ");
    $stmt->execute([$postId]);
    $answerVotesDeleted = $stmt->rowCount();
    
    // Finally delete the post
    $stmt = $pdo->prepare("DELETE FROM posts WHERE id = ?");
    $stmt->execute([$postId]);
    
    if ($stmt->rowCount() === 0) {
        $pdo->rollBack();
        echo json_encode(['error' => 'Failed to delete post']);
        exit;
    }
    
    // Commit the transaction
    $pdo->commit();
    
    echo json_encode([
        'success' => true,
        'message' => "Post '{$post['title']}' deleted successfully",
        'deleted_post' => [
            'id' => $post['id'],
            'title' => $post['title'],
            'author' => $post['author_username'],
            'category' => $post['category_name'],
            'created_at' => $post['created_at']
        ],
        'cleanup_stats' => [
            'answers_deleted' => $answersDeleted,
            'post_votes_deleted' => $postVotesDeleted,
            'answer_votes_deleted' => $answerVotesDeleted,
            'total_items_deleted' => 1 + $answersDeleted + $postVotesDeleted + $answerVotesDeleted
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
    echo json_encode(['error' => 'Failed to delete post: '.$e->getMessage()]);
}
?>
