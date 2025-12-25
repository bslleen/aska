<?php
header('Content-Type: application/json');

require 'db.php';
require 'token_utils.php';

$student_id = $_GET['student_id'] ?? null;

if (!$student_id) {
    http_response_code(400);
    echo json_encode(['error' => 'student_id is required']);
    exit;
}

try {
    // Verify the student exists and has student role
    $stmt = $pdo->prepare("SELECT id, username FROM users WHERE id = ? AND user_type = 'student'");
    $stmt->execute([$student_id]);
    $student = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$student) {
        http_response_code(404);
        echo json_encode(['error' => 'Student not found']);
        exit;
    }

    // Get student's questions with answers
    $sql = "SELECT 
                p.id AS post_id,
                p.title,
                p.content,
                p.created_at,
                c.name AS category_name,
                c.id AS category_id,
                (SELECT COUNT(*) FROM answers a WHERE a.post_id = p.id) AS answer_count,
                (SELECT COUNT(*) FROM answers a WHERE a.post_id = p.id AND a.is_accepted = 1) AS accepted_answers
            FROM posts p
            JOIN categories c ON p.category_id = c.id
            WHERE p.user_id = ?
            ORDER BY p.created_at DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$student_id]);
    $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // For each question, get the answers (including private ones for this student)
    foreach ($questions as &$question) {
        $stmt = $pdo->prepare("
            SELECT 
                a.id AS answer_id,
                a.content,
                u.username AS author,
                a.is_accepted,
                a.visibility,
                a.created_at
            FROM answers a
            JOIN users u ON a.user_id = u.id
            WHERE a.post_id = ? 
            AND (a.visibility = 'public' OR a.target_student_id = ?)
            ORDER BY a.is_accepted DESC, a.created_at ASC
        ");
        $stmt->execute([$question['post_id'], $student_id]);
        $question['answers'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Get student's private answers (where they are the target)
    $stmt = $pdo->prepare("
        SELECT 
            a.id AS answer_id,
            a.content,
            u.username AS author,
            a.created_at,
            p.title AS post_title,
            p.id AS post_id
        FROM answers a
        JOIN users u ON a.user_id = u.id
        JOIN posts p ON a.post_id = p.id
        WHERE a.target_student_id = ?
        ORDER BY a.created_at DESC
    ");
    $stmt->execute([$student_id]);
    $private_answers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Get categories the student has asked questions in
    $stmt = $pdo->prepare("
        SELECT DISTINCT c.id, c.name
        FROM categories c
        JOIN posts p ON c.id = p.category_id
        WHERE p.user_id = ?
        ORDER BY c.name
    ");
    $stmt->execute([$student_id]);
    $used_categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'student' => $student,
        'questions' => $questions,
        'private_answers' => $private_answers,
        'used_categories' => $used_categories,
        'stats' => [
            'total_questions' => count($questions),
            'total_answers_received' => array_sum(array_column($questions, 'answer_count')),
            'private_answers' => count($private_answers),
            'accepted_answers' => array_sum(array_column($questions, 'accepted_answers'))
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
