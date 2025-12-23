<?php
header('Content-Type: application/json');
require_once 'db.php';

try {
    $stmt = $pdo->query("SELECT id, username, email FROM users");
    $users = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'users' => $users,
        'count' => count($users)
    ]);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to fetch users: '.$e->getMessage()]);
}
?>
