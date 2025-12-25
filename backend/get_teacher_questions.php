<?php
header('Content-Type: application/json');

require 'db.php';
require 'token_utils.php';

$teacher_id = $_GET['teacher_id'] ?? null;

if (!$teacher_id) {
    http_response_code(400);
    echo json_encode(['error' => 'teacher_id is required']);
    exit;
}

try {
    // Verify the teacher exists and has teacher role
    $stmt = $pdo->prepare("SELECT id, username FROM users WHERE id = ? AND user_type = 'teacher'");
    $stmt->execute([$teacher_id]);
    $teacher = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$teacher) {
        http_response_code(404);
        echo json_encode(['error' => 'Teacher not found']);
        exit;
    }

    // Get questions for teacher's assigned categories
    $sql = "SELECT 
                p.id AS post_id,
                p.title,
                p.content,
                p.created_at,
                u.username AS student_name,
                c.name AS category_name,
                c.id AS category_id,
                (SELECT COUNT(*) FROM answers a WHERE a.post_id = p.id) AS answer_count,
                (SELECT COUNT(*) FROM answers a WHERE a.post_id = p.id AND a.is_accepted = 1) AS accepted_answers
            FROM posts p
            JOIN users u ON p.user_id = u.id
            JOIN categories c ON p.category_id = c.id
            JOIN category_teachers ct ON c.id = ct.category_id
            WHERE ct.teacher_id = ?
            ORDER BY p.created_at DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$teacher_id]);
    $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Get teacher's assigned categories for context
    $stmt = $pdo->prepare("
        SELECT c.id, c.name
        FROM categories c
        JOIN category_teachers ct ON c.id = ct.category_id
        WHERE ct.teacher_id = ?
        ORDER BY c.name
    ");
    $stmt->execute([$teacher_id]);
    $assigned_categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'teacher' => $teacher,
        'assigned_categories' => $assigned_categories,
        'questions' => $questions,
        'total_questions' => count($questions)
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
