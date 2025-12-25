<?php
header('Content-Type: application/json');

require 'db.php';

try {
    $changes = [];

    // 1. Create category_teachers junction table
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS category_teachers (
                id INT AUTO_INCREMENT PRIMARY KEY,
                category_id INT NOT NULL,
                teacher_id INT NOT NULL,
                assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
                FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE KEY unique_teacher_category (category_id, teacher_id),
                INDEX idx_teacher_id (teacher_id),
                INDEX idx_category_id (category_id)
            )
        ");
        $changes[] = 'category_teachers table created';
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'already exists') === false) {
            throw $e;
        }
    }

    // 2. Add privacy controls to answers table
    try {
        $pdo->exec("
            ALTER TABLE answers 
            ADD COLUMN visibility ENUM('public', 'private') DEFAULT 'public' AFTER content
        ");
        $pdo->exec("
            ALTER TABLE answers 
            ADD COLUMN target_student_id INT NULL AFTER visibility
        ");
        $pdo->exec("
            ALTER TABLE answers 
            ADD INDEX idx_visibility (visibility)
        ");
        $pdo->exec("
            ALTER TABLE answers 
            ADD INDEX idx_target_student (target_student_id)
        ");
        $changes[] = 'answers privacy columns added';
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column name') === false) {
            throw $e;
        } else {
            $changes[] = 'answers privacy columns already exist';
        }
    }

    // 3. Update existing answers to be public (default)
    try {
        $pdo->exec("
            UPDATE answers SET visibility = 'public' WHERE visibility IS NULL
        ");
        $changes[] = 'existing answers set to public visibility';
    } catch (PDOException $e) {
        // If column doesn't exist yet, this is fine - continue
    }

    echo json_encode([
        'success' => true,
        'message' => 'QA System database schema updated successfully',
        'changes' => $changes
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Migration failed: ' . $e->getMessage()
    ]);
}
?>
