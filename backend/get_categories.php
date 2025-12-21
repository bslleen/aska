<?php
header('Content-Type: application/json');

// Include your database connection
require 'db.php';

try {
    $stmt = $conn->prepare("SELECT id, name FROM category ORDER BY name ASC");
    $stmt->execute();
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($categories);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>