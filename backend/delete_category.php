<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';
require_once 'token_utils.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Get authorization header
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = null;

if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}

// Validate token and get user ID
$payload = validateTokenWithBlacklist($token);
if (!$payload) {
    echo json_encode(['error' => 'User not authenticated']);
    exit;
}

$userId = $payload['user_id'];

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['category_id']) || empty($input['category_id'])) {
    echo json_encode(['error' => 'Category ID is required']);
    exit;
}

$categoryId = intval($input['category_id']);

if ($categoryId <= 0) {
    echo json_encode(['error' => 'Invalid category ID']);
    exit;
}

try {
    // Check if category exists
    $stmt = $pdo->prepare("SELECT id, name FROM categories WHERE id = ?");
    $stmt->execute([$categoryId]);
    $category = $stmt->fetch();
    
    if (!$category) {
        echo json_encode(['error' => 'Category not found']);
        exit;
    }
    
    // Check if category is being used by any posts
    $stmt = $pdo->prepare("SELECT COUNT(*) as post_count FROM posts WHERE category_id = ?");
    $stmt->execute([$categoryId]);
    $result = $stmt->fetch();
    
    if ($result['post_count'] > 0) {
        echo json_encode(['error' => 'Cannot delete category that has posts. Please delete or reassign posts first.']);
        exit;
    }
    
    // Delete the category
    $stmt = $pdo->prepare("DELETE FROM categories WHERE id = ?");
    $stmt->execute([$categoryId]);
    
    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Category deleted successfully',
            'category' => [
                'id' => $categoryId,
                'name' => $category['name']
            ]
        ]);
    } else {
        echo json_encode(['error' => 'Failed to delete category']);
    }
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Database error: '.$e->getMessage()]);
} catch (Exception $e) {
    echo json_encode(['error' => 'Delete failed: '.$e->getMessage()]);
}
?>
