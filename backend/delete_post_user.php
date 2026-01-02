<?php
header('Content-Type: application/json');

require 'db.php';
require 'token_utils.php';

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate auth token
$token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = str_replace('Bearer ', '', $token);

$userId = validateToken($token);
if (!$userId) {
    http_response_code(401);
    echo json_encode(['error' => 'Invalid or expired token']);
    exit;
}

// Get post ID
$postId = $input['post_id'] ?? 0;

if (!$postId) {
    http_response_code(400);
    echo json_encode(['error' => 'post_id is required']);
    exit;
}

try {
    // Verify ownership
    $stmt = $pdo->prepare("SELECT user_id FROM posts WHERE id = ?");
    $stmt->execute([$postId]);
    $post = $stmt->fetch();

    if (!$post) {
        http_response_code(404);
        echo json_encode(['error' => 'Post not found']);
        exit;
    }

    if ($post['user_id'] != $userId) {
        http_response_code(403);
        echo json_encode(['error' => 'You can only delete your own posts']);
        exit;
    }

    // Delete associated answers first
    $stmt = $pdo->prepare("DELETE FROM answers WHERE post_id = ?");
    $stmt->execute([$postId]);

    // Delete associated votes
    $stmt = $pdo->prepare("DELETE FROM votes WHERE post_id = ?");
    $stmt->execute([$postId]);

    // Delete the post
    $stmt = $pdo->prepare("DELETE FROM posts WHERE id = ?");
    $stmt->execute([$postId]);

    echo json_encode([
        'success' => true,
        'message' => 'Post deleted successfully'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>

