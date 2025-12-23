<?php
// CORS configuration for Flutter app with cookies
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Simple API response for root endpoint
echo json_encode([
    'status' => 'API is running',
    'message' => 'Welcome to ASKA Backend API',
    'version' => '1.0.0',
    'endpoints' => [
        'login' => '/login.php',
        'register' => '/register.php',
        'logout' => '/logout.php',
        'get_user' => '/get_user.php',
        'update_user' => '/update_user.php',
        'get_posts' => '/get_posts.php',
        'create_post' => '/create_post.php',
        'get_answers' => '/get_answers.php',
        'create_answer' => '/create_answer.php',
        'vote' => '/vote.php',
        'get_categories' => '/get_categories.php',
        'create_category' => '/create_category.php',
        'delete_category' => '/delete_category.php',
    ]
]);
?>
