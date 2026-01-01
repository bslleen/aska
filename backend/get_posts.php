<?php
require 'db.php';

$sql = "SELECT 
            p.id AS post_id, 
            p.title, 
            p.content, 
            u.username AS author, 
            c.name AS category, 
            p.status,
            p.created_at,
            (SELECT COUNT(*) FROM answers WHERE post_id = p.id) AS reply_count
        FROM posts p
        JOIN users u ON p.user_id = u.id
        JOIN categories c ON p.category_id = c.id
        ORDER BY p.created_at DESC";

$stmt = $pdo->query($sql);
$posts = $stmt->fetchAll();

// Format created_at for each post
foreach ($posts as &$post) {
    $post['created_at'] = $post['created_at'];
    $post['reply_count'] = (int)$post['reply_count'];
}

echo json_encode($posts);
?>

