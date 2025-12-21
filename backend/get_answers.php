<?php
require 'db.php';

$post_id = $_GET['post_id'] ?? 0;

$sql = "SELECT a.id AS answer_id, a.content, u.username AS author, a.is_accepted
        FROM answers a
        JOIN users u ON a.user_id = u.id
        WHERE a.post_id = ?
        ORDER BY a.is_accepted DESC, a.created_at ASC";

$stmt = $pdo->prepare($sql);
$stmt->execute([$post_id]);
$answers = $stmt->fetchAll();

echo json_encode($answers);
?>
