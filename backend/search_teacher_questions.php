<?php
// Search Teacher Questions - Search for students or keywords in questions
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';
require_once 'token_utils.php';

// Get parameters
$teacher_id = $_GET['teacher_id'] ?? null;
$search_query = $_GET['query'] ?? '';
$search_type = $_GET['search_type'] ?? 'all'; // 'student', 'keyword', 'all'
$category_id = $_GET['category_id'] ?? null;

if (!$teacher_id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'teacher_id is required']);
    exit;
}

try {
    // Verify the teacher exists and has teacher role
    $stmt = $pdo->prepare("SELECT id, username FROM users WHERE id = ? AND user_type = 'teacher'");
    $stmt->execute([$teacher_id]);
    $teacher = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$teacher) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Teacher not found']);
        exit;
    }

    // Build the base query
    $sql = "SELECT 
                p.id AS post_id,
                p.title,
                p.content,
                p.created_at,
                u.username AS student_name,
                u.id AS student_id,
                c.name AS category_name,
                c.id AS category_id,
                (SELECT COUNT(*) FROM answers a WHERE a.post_id = p.id) AS answer_count,
                (SELECT COUNT(*) FROM answers a WHERE a.post_id = p.id AND a.is_accepted = 1) AS accepted_answers
            FROM posts p
            JOIN users u ON p.user_id = u.id
            JOIN categories c ON p.category_id = c.id
            JOIN category_teachers ct ON c.id = ct.category_id
            WHERE ct.teacher_id = ?";
    
    $params = [$teacher_id];
    
    // Add search conditions
    if (!empty($search_query)) {
        $search_query = '%' . $search_query . '%';
        
        if ($search_type === 'student') {
            // Search only by student name
            $sql .= " AND u.username LIKE ?";
            $params[] = $search_query;
        } elseif ($search_type === 'keyword') {
            // Search only in title and content
            $sql .= " AND (p.title LIKE ? OR p.content LIKE ?)";
            $params[] = $search_query;
            $params[] = $search_query;
        } else {
            // Search everywhere (student name, title, and content)
            $sql .= " AND (u.username LIKE ? OR p.title LIKE ? OR p.content LIKE ?)";
            $params[] = $search_query;
            $params[] = $search_query;
            $params[] = $search_query;
        }
    }
    
    // Add category filter
    if ($category_id && $category_id !== 'all') {
        $sql .= " AND c.id = ?";
        $params[] = $category_id;
    }
    
    $sql .= " ORDER BY p.created_at DESC";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Get teacher's assigned categories for the filter dropdown
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
        'success' => true,
        'teacher' => $teacher,
        'assigned_categories' => $assigned_categories,
        'questions' => $questions,
        'total_questions' => count($questions),
        'search_info' => [
            'query' => $_GET['query'] ?? '',
            'search_type' => $search_type,
            'category_id' => $category_id
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>

