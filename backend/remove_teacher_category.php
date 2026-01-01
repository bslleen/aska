<?php
/**
 * Remove Teacher from Category Assignment
 * 
 * Admin endpoint to remove a teacher from a category assignment
 * 
 * POST parameters:
 * - assignment_id: The ID of the category_teachers assignment to remove
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';
require_once 'token_utils.php';
require_once 'admin_middleware.php';

global $pdo;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = null;

if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}

$adminPayload = checkAdminAccess($token);
if (!$adminPayload) {
    exit;
}

// Get input data
$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['assignment_id']) || empty($input['assignment_id'])) {
    echo json_encode(['success' => false, 'error' => 'Assignment ID is required']);
    exit;
}

$assignmentId = (int)$input['assignment_id'];

try {
    // Verify assignment exists
    $stmt = $pdo->prepare("SELECT id, category_id, teacher_id FROM category_teachers WHERE id = ?");
    $stmt->execute([$assignmentId]);
    $assignment = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$assignment) {
        echo json_encode(['success' => false, 'error' => 'Assignment not found']);
        exit;
    }
    
    // Delete the assignment
    $stmt = $pdo->prepare("DELETE FROM category_teachers WHERE id = ?");
    $stmt->execute([$assignmentId]);
    
    // Get teacher and category names for the message
    $stmt = $pdo->prepare("
        SELECT u.username as teacher_name, c.name as category_name 
        FROM category_teachers ct
        JOIN users u ON ct.teacher_id = u.id
        JOIN categories c ON ct.category_id = c.id
        WHERE ct.id = ?
    ");
    $stmt->execute([$assignmentId]);
    $info = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'message' => "Successfully removed teacher from category",
        'deleted_assignment' => [
            'id' => $assignmentId,
            'teacher_id' => $assignment['teacher_id'],
            'category_id' => $assignment['category_id']
        ]
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => 'Failed to remove assignment: '.$e->getMessage()]);
}
?>

