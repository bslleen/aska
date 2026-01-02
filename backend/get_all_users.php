<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';
require_once 'token_utils.php';
require_once 'admin_middleware.php';

// Make sure database connection is available globally
global $pdo;

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Verify admin access
$adminPayload = verifyAdminAccess();
if (isset($adminPayload['error'])) {
    echo json_encode(['success' => false, 'error' => $adminPayload['error']]);
    exit;
}

try {
    // Get all users with their information
    $stmt = $pdo->query("
        SELECT 
            id, 
            username, 
            email, 
            full_name, 
            bio, 
            user_type, 
            trust_score,
            created_at,
            CASE 
                WHEN user_type = 'admin' THEN '👑 Admin'
                WHEN user_type = 'teacher' THEN '👨‍🏫 Teacher'
                ELSE '👨‍🎓 Student'
            END as role_display
        FROM users 
        ORDER BY 
            CASE user_type 
                WHEN 'admin' THEN 1 
                WHEN 'teacher' THEN 2 
                ELSE 3 
            END, 
            username
    ");
    
    $users = $stmt->fetchAll();
    
    // Get additional stats for each user
    $usersWithStats = [];
    foreach ($users as $user) {
        // Get post count
        $stmt = $pdo->prepare("SELECT COUNT(*) as post_count FROM posts WHERE user_id = ?");
        $stmt->execute([$user['id']]);
        $postStats = $stmt->fetch();
        
        // Get answer count
        $stmt = $pdo->prepare("SELECT COUNT(*) as answer_count FROM answers WHERE user_id = ?");
        $stmt->execute([$user['id']]);
        $answerStats = $stmt->fetch();
        
        $user['post_count'] = (int)$postStats['post_count'];
        $user['answer_count'] = (int)$answerStats['answer_count'];
        $user['total_contributions'] = $user['post_count'] + $user['answer_count'];
        
        $usersWithStats[] = $user;
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Users retrieved successfully',
        'data' => $usersWithStats,
        'total_users' => count($usersWithStats),
        'admin_info' => [
            'id' => $adminPayload['user_id'],
            'username' => 'lea', // This would be dynamic in real scenario
            'timestamp' => date('Y-m-d H:i:s')
        ]
    ]);
    
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to retrieve users: '.$e->getMessage()]);
}
?>

