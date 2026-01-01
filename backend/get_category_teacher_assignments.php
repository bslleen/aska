<?php
/**
 * Get All Category-Teacher Assignments
 * 
 * Admin endpoint to get all category-teacher assignments
 * with all teachers for selection
 * 
 * GET parameters: none (uses auth token from header)
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';
require_once 'token_utils.php';
require_once 'admin_middleware.php';

global $pdo;

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
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

try {
    // Get all categories with their assigned teachers
    $stmt = $pdo->query("
        SELECT 
            c.id as category_id,
            c.name as category_name,
            c.description as category_description,
            ct.id as assignment_id,
            ct.teacher_id,
            ct.assigned_at,
            u.username as teacher_username,
            u.full_name as teacher_name,
            u.email as teacher_email
        FROM categories c
        LEFT JOIN category_teachers ct ON c.id = ct.category_id
        LEFT JOIN users u ON ct.teacher_id = u.id
        ORDER BY c.name ASC, ct.assigned_at ASC
    ");
    
    $assignments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Organize by category
    $categoriesData = [];
    foreach ($assignments as $row) {
        $catId = $row['category_id'];
        
        if (!isset($categoriesData[$catId])) {
            $categoriesData[$catId] = [
                'id' => (int)$catId,
                'name' => $row['category_name'],
                'description' => $row['category_description'],
                'assigned_teachers' => [],
                'assignment_ids' => []
            ];
        }
        
        if ($row['teacher_id']) {
            $categoriesData[$catId]['assigned_teachers'][] = [
                'id' => (int)$row['teacher_id'],
                'username' => $row['teacher_username'],
                'full_name' => $row['teacher_name'],
                'email' => $row['teacher_email'],
                'assigned_at' => $row['assigned_at']
            ];
        }
    }
    
    // Get all teachers for selection dropdown
    $stmt = $pdo->query("
        SELECT id, username, full_name, email
        FROM users
        WHERE user_type = 'teacher'
        ORDER BY username ASC
    ");
    $allTeachers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'message' => 'Category-teacher assignments retrieved successfully',
        'categories' => array_values($categoriesData),
        'all_teachers' => array_map(function($t) {
            return [
                'id' => (int)$t['id'],
                'username' => $t['username'],
                'full_name' => $t['full_name'],
                'email' => $t['email']
            ];
        }, $allTeachers),
        'total_assignments' => count(array_filter($assignments, fn($a) => $a['teacher_id'] !== null))
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to retrieve assignments: '.$e->getMessage()]);
}
?>

