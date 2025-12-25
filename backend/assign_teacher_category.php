<?php
header('Content-Type: application/json');

require 'db.php';
require 'admin_middleware.php';
require 'token_utils.php';

// Get input data
$input = json_decode(file_get_contents('php://input'), true);
$category_id = $input['category_id'] ?? null;
$teacher_id = $input['teacher_id'] ?? null;

if (!$category_id || !$teacher_id) {
    http_response_code(400);
    echo json_encode(['error' => 'category_id and teacher_id are required']);
    exit;
}

try {
    // Verify that the category exists
    $stmt = $pdo->prepare("SELECT id FROM categories WHERE id = ?");
    $stmt->execute([$category_id]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode(['error' => 'Category not found']);
        exit;
    }

    // Verify that the teacher exists and has 'teacher' role
    $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND user_type = 'teacher'");
    $stmt->execute([$teacher_id]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode(['error' => 'Teacher not found']);
        exit;
    }

    // Check if assignment already exists
    $stmt = $pdo->prepare("SELECT id FROM category_teachers WHERE category_id = ? AND teacher_id = ?");
    $stmt->execute([$category_id, $teacher_id]);
    if ($stmt->fetch()) {
        http_response_code(409);
        echo json_encode(['error' => 'Teacher is already assigned to this category']);
        exit;
    }

    // Create the assignment
    $stmt = $pdo->prepare("INSERT INTO category_teachers (category_id, teacher_id) VALUES (?, ?)");
    $stmt->execute([$category_id, $teacher_id]);
    $assignment_id = $pdo->lastInsertId();

    // Get the created assignment with details
    $stmt = $pdo->prepare("
        SELECT ct.*, c.name as category_name, u.username as teacher_name
        FROM category_teachers ct
        JOIN categories c ON ct.category_id = c.id
        JOIN users u ON ct.teacher_id = u.id
        WHERE ct.id = ?
    ");
    $stmt->execute([$assignment_id]);
    $assignment = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'message' => 'Teacher successfully assigned to category',
        'assignment' => $assignment
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
