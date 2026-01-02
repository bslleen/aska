<?php
header('Content-Type: application/json');

require 'db.php';
require 'token_utils.php';

$post_id = $_GET['post_id'] ?? 0;
$current_user_id = $_GET['current_user_id'] ?? null;

if (!$post_id) {
    http_response_code(400);
    echo json_encode(['error' => 'post_id is required']);
    exit;
}

try {
    $sql = "SELECT 
                a.id AS answer_id, 
                a.user_id,
                a.content, 
                u.username AS author, 
                a.is_accepted,
                a.visibility,
                a.target_student_id,
                a.created_at
            FROM answers a
            JOIN users u ON a.user_id = u.id
            WHERE a.post_id = ?";

    $params = [$post_id];

    // Apply privacy filtering
    if ($current_user_id) {
        // User can see:
        // 1. All public answers
        // 2. Private answers where they are the target student
        // 3. Their own private answers (if they created them)
        $sql .= " AND (a.visibility = 'public' OR a.target_student_id = ? OR a.user_id = ?)";
        $params[] = $current_user_id;
        $params[] = $current_user_id;
    } else {
        // No user specified, only show public answers
        $sql .= " AND a.visibility = 'public'";
    }

    $sql .= " ORDER BY a.is_accepted DESC, a.created_at ASC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $answers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Process answers to add privacy info
    foreach ($answers as &$answer) {
        $answer['is_private'] = $answer['visibility'] === 'private';
        $answer['is_own_private_answer'] = $answer['visibility'] === 'private' && 
                                          $current_user_id && 
                                          $answer['target_student_id'] == $current_user_id;
        
        // For private answers, only show target student info to authorized users
        if ($answer['visibility'] === 'private' && $current_user_id) {
            if ($answer['target_student_id'] == $current_user_id || $answer['target_student_id'] == null) {
                // Student can see it's addressed to them, or it's their own answer
                $answer['privacy_info'] = 'Private answer';
            } else {
                // Hide private answer details from unauthorized users
                unset($answer['target_student_id']);
                $answer['content'] = '[Private Answer]';
                $answer['privacy_info'] = 'Private answer (not for you)';
            }
        }
    }

    echo json_encode($answers);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
