<?php
header('Content-Type: application/json');
require_once 'db.php';

// Create token_blacklist table if it doesn't exist
$sql = "
CREATE TABLE IF NOT EXISTS token_blacklist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    token_hash VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    invalidated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_token (token_hash)
)";

try {
    $pdo->exec($sql);
    echo json_encode(['success' => true, 'message' => 'Token blacklist table created successfully']);
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to create token blacklist table: '.$e->getMessage()]);
}
?>
