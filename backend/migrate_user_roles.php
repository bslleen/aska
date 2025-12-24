<?php
header('Content-Type: application/json');
require_once 'db.php';

// Check if user_type column exists, if not add it
try {
    // Check if column exists
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'user_type'");
    
    if (!$stmt->fetch()) {
        // Add user_type column if it doesn't exist
        $pdo->exec("ALTER TABLE users ADD COLUMN user_type ENUM('student', 'teacher') DEFAULT 'student'");
        echo json_encode(['success' => true, 'message' => 'Added user_type column to users table']);
    } else {
        // Column exists, set default for any NULL values
        $stmt = $pdo->prepare("UPDATE users SET user_type = 'student' WHERE user_type IS NULL");
        $stmt->execute();
        $affected = $stmt->rowCount();
        echo json_encode(['success' => true, 'message' => "Updated {$affected} existing users to have 'student' role"]);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => 'Migration failed: '.$e->getMessage()]);
}
?>
