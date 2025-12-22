<?php
require 'db.php';

$data = json_decode(file_get_contents('php://input'), true);

$user_id = $data['user_id'] ?? null;
$post_id = $data['post_id'] ?? null;
$content = $data['content'] ?? '';

if (!$user_id || !$post_id || !$content) {
    echo json_encode(['error' => 'Missing fields']);
    exit;
}

$sql = "INSERT INTO answers (user_id, post_id, content) VALUES (?, ?, ?)";
$stmt = $pdo->prepare($sql);
$stmt->execute([$user_id, $post_id, $content]);

echo json_encode(['success' => true, 'answer_id' => $pdo->lastInsertId()]);
?>
