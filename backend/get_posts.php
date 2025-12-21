<?php
require 'db.php';

$sql = "SELECT p.id AS post_id, p.title, p.content, u.username AS author, c.name AS category, p.status
        FROM posts p
        JOIN users u ON p.user_id = u.id
        JOIN categories c ON p.category_id = c.id
        ORDER BY p.created_at DESC";

$stmt = $pdo->query($sql);
$posts = $stmt->fetchAll();

echo json_encode($posts);
?>
