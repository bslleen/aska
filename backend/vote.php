<?php
require 'db.php';

$data = json_decode(file_get_contents('php://input'), true);

$user_id = $data['user_id'] ?? null;
$target_type = $data['target_type'] ?? '';
$target_id = $data['target_id'] ?? null;
$value = $data['value'] ?? null; // 1 for upvote, -1 for downvote

if (!$user_id || !$target_type || !$target_id || !in_array($value, [1, -1])) {
    echo json_encode(['error' => 'Invalid data']);
    exit;
}

$sql = "INSERT INTO votes (user_id, target_type, target_id, value) VALUES (?, ?, ?, ?)";
$stmt = $pdo->prepare($sql);
$stmt->execute([$user_id, $target_type, $target_id, $value]);

echo json_encode(['success' => true, 'vote_id' => $pdo->lastInsertId()]);
?>
