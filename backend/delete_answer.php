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

// Get answer ID
$answerId = $input['answer_id'] ?? 0;

if (!$answerId) {
    http_response_code(400);
    echo json_encode(['error' => 'answer_id is required']);
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
        echo json_encode(['error' => 'You can only delete your own answers']);
        exit;
    }

    // Get post_id for reply count update (not needed as we count dynamically)
    
    // Delete associated votes
    $stmt = $pdo->prepare("DELETE FROM votes WHERE answer_id = ?");
    $stmt->execute([$answerId]);

    // Delete the answer
    $stmt = $pdo->prepare("DELETE FROM answers WHERE id = ?");
    $stmt->execute([$answerId]);

    echo json_encode([
        'success' => true,
        'message' => 'Answer deleted successfully'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>

