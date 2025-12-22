<?php
header('Content-Type: application/json');

require 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['user_id']) || !isset($input['category_id']) || !isset($input['title']) || !isset($input['content'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

if (trim($input['title']) === '' || trim($input['content']) === '') {
    http_response_code(400);
    echo json_encode(['error' => 'Title and content are required']);
    exit;
}

try {
    $stmt = $pdo->prepare("INSERT INTO posts (user_id, category_id, title, content) VALUES (?, ?, ?, ?)");
    $stmt->execute([
        $input['user_id'],
        $input['category_id'],
        trim($input['title']),
        trim($input['content'])
    ]);
    
    $postId = $pdo->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'id' => $postId,
        'title' => trim($input['title']),
        'content' => trim($input['content'])
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to create post: ' . $e->getMessage()]);
}
?>
