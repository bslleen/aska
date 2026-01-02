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

// Get post data
$postId = $input['post_id'] ?? 0;
$title = $input['title'] ?? null;
$content = $input['content'] ?? null;

if (!$postId) {
    http_response_code(400);
    echo json_encode(['error' => 'post_id is required']);
    exit;
}

if ($title === null && $content === null) {
    http_response_code(400);
    echo json_encode(['error' => 'At least title or content must be provided']);
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
        echo json_encode(['error' => 'You can only edit your own posts']);
        exit;
    }

    // Build update query
    $updates = [];
    $params = [];

    if ($title !== null) {
        $updates[] = "title = ?";
        $params[] = $title;
    }

    if ($content !== null) {
        $updates[] = "content = ?";
        $params[] = $content;
    }

    if (empty($updates)) {
        http_response_code(400);
        echo json_encode(['error' => 'No fields to update']);
        exit;
    }

    $params[] = $postId;
    $sql = "UPDATE posts SET " . implode(', ', $updates) . " WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    echo json_encode([
        'success' => true,
        'message' => 'Post updated successfully'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>

