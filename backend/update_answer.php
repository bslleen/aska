<?php
header('Content-Type: application/json');

require 'db.php';
require 'token_utils.php';

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate auth token
$token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = str_replace('Bearer ', '', $token);

$userId = validateToken($token);
if (!$userId) {
    http_response_code(401);
    echo json_encode(['error' => 'Invalid or expired token']);
    exit;
}

// Get answer data
$answerId = $input['answer_id'] ?? 0;
$content = $input['content'] ?? null;

if (!$answerId) {
    http_response_code(400);
    echo json_encode(['error' => 'answer_id is required']);
    exit;
}

if ($content === null || trim($content) === '') {
    http_response_code(400);
    echo json_encode(['error' => 'Content is required']);
    exit;
}

try {
    // Verify ownership
    $stmt = $pdo->prepare("SELECT user_id FROM answers WHERE id = ?");
    $stmt->execute([$answerId]);
    $answer = $stmt->fetch();

    if (!$answer) {
        http_response_code(404);
        echo json_encode(['error' => 'Answer not found']);
        exit;
    }

    if ($answer['user_id'] != $userId) {
        http_response_code(403);
        echo json_encode(['error' => 'You can only edit your own answers']);
        exit;
    }

    // Update the answer
    $stmt = $pdo->prepare("UPDATE answers SET content = ? WHERE id = ?");
    $stmt->execute([$content, $answerId]);

    echo json_encode([
        'success' => true,
        'message' => 'Answer updated successfully'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>

