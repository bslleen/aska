<?php
header('Content-Type: application/json');
require_once 'db.php';

// Create users table if it doesn't exist
$sql = "
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    bio TEXT,
    user_type ENUM('student', 'teacher') DEFAULT 'student',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)";

try {
    $pdo->exec($sql);
    echo json_encode(['success' => true, 'message' => 'Users table created successfully']);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to create users table: '.$e->getMessage()]);
}
?>
