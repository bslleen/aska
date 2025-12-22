<?php
header('Content-Type: application/json');

require 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['name']) || trim($input['name']) === '') {
    http_response_code(400);
    echo json_encode(['error' => 'Category name is required']);
    exit;
}

try {
    $stmt = $pdo->prepare("INSERT INTO categories (name) VALUES (?)");
    $stmt->execute([trim($input['name'])]);
    
    $categoryId = $pdo->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'id' => $categoryId,
        'name' => trim($input['name'])
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to create category: ' . $e->getMessage()]);
}
?>
