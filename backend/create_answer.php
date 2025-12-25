<?php
header('Content-Type: application/json');

require 'db.php';
require 'token_utils.php';

$data = json_decode(file_get_contents('php://input'), true);

$user_id = $data['user_id'] ?? null;
$post_id = $data['post_id'] ?? null;
$content = $data['content'] ?? '';
$visibility = $data['visibility'] ?? 'public';
$target_student_id = $data['target_student_id'] ?? null;

// Validate required fields
if (!$user_id || !$post_id || !$content) {
    http_response_code(400);
    echo json_encode(['error' => 'user_id, post_id, and content are required']);
    exit;
}

// Validate visibility
if (!in_array($visibility, ['public', 'private'])) {
    http_response_code(400);
    echo json_encode(['error' => 'visibility must be "public" or "private"']);
    exit;
}

// Validate that private answers have a target student
if ($visibility === 'private' && !$target_student_id) {
    http_response_code(400);
    echo json_encode(['error' => 'target_student_id is required for private answers']);
    exit;
}

try {
    // Verify the post exists
    $stmt = $pdo->prepare("SELECT id, user_id FROM posts WHERE id = ?");
    $stmt->execute([$post_id]);
    $post = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$post) {
        http_response_code(404);
        echo json_encode(['error' => 'Post not found']);
        exit;
    }

    // If private answer, verify target student exists
    if ($visibility === 'private') {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ?");
        $stmt->execute([$target_student_id]);
        if (!$stmt->fetch()) {
            http_response_code(404);
            echo json_encode(['error' => 'Target student not found']);
            exit;
        }
    }

    // Insert the answer
    $sql = "INSERT INTO answers (user_id, post_id, content, visibility, target_student_id) VALUES (?, ?, ?, ?, ?)";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$user_id, $post_id, $content, $visibility, $target_student_id]);

    $answer_id = $pdo->lastInsertId();

    // Get the created answer with additional info
    $stmt = $pdo->prepare("
        SELECT a.*, u.username as author, p.title as post_title
        FROM answers a
        JOIN users u ON a.user_id = u.id
        JOIN posts p ON a.post_id = p.id
        WHERE a.id = ?
    ");
    $stmt->execute([$answer_id]);
    $answer = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'message' => 'Answer created successfully',
        'answer_id' => $answer_id,
        'answer' => $answer
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
