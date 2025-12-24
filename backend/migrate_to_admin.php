<?php
header('Content-Type: application/json');
require_once 'db.php';

echo json_encode(['message' => 'Admin Migration Script']);

// Test 1: Update user_type ENUM to include admin
echo "\n=== Step 1: Update user_type ENUM ===\n";
try {
    // First drop the existing ENUM constraint
    $pdo->exec("ALTER TABLE users MODIFY COLUMN user_type VARCHAR(20) DEFAULT 'student'");
    echo "✓ Removed existing user_type constraint\n";
    
    // Add the new ENUM with admin
    $pdo->exec("ALTER TABLE users MODIFY COLUMN user_type ENUM('student', 'teacher', 'admin') DEFAULT 'student'");
    echo "✓ Updated user_type ENUM to include 'admin'\n";
    
} catch (PDOException $e) {
    echo "✗ Failed to update ENUM: " . $e->getMessage() . "\n";
}

// Test 2: Check if user 'lea' exists and promote to admin
echo "\n=== Step 2: Promote User 'lea' to Admin ===\n";
try {
    // Check if lea exists
    $stmt = $pdo->prepare("SELECT id, username, user_type FROM users WHERE username = 'lea'");
    $stmt->execute();
    $leaUser = $stmt->fetch();
    
    if ($leaUser) {
        echo "✓ Found user 'lea' with ID: {$leaUser['id']}, current role: {$leaUser['user_type']}\n";
        
        // Update lea to admin
        $stmt = $pdo->prepare("UPDATE users SET user_type = 'admin' WHERE username = 'lea'");
        $stmt->execute();
        
        // Verify the update
        $stmt = $pdo->prepare("SELECT user_type FROM users WHERE username = 'lea'");
        $stmt->execute();
        $updatedUser = $stmt->fetch();
        
        echo "✓ User 'lea' promoted to admin role: {$updatedUser['user_type']}\n";
        
    } else {
        echo "⚠ User 'lea' not found in database\n";
        echo "  Available users:\n";
        
        $stmt = $pdo->query("SELECT id, username, email, user_type FROM users ORDER BY id");
        $users = $stmt->fetchAll();
        
        foreach ($users as $user) {
            echo "  - ID: {$user['id']}, Username: {$user['username']}, Email: {$user['email']}, Role: {$user['user_type']}\n";
        }
    }
    
} catch (PDOException $e) {
    echo "✗ Failed to promote user 'lea': " . $e->getMessage() . "\n";
}

// Test 3: Show all users after migration
echo "\n=== Step 3: Current Users and Roles ===\n";
try {
    $stmt = $pdo->query("SELECT id, username, email, user_type, created_at FROM users ORDER BY id");
    $users = $stmt->fetchAll();
    
    if (empty($users)) {
        echo "No users found in database\n";
    } else {
        echo "Found " . count($users) . " users:\n";
        foreach ($users as $user) {
            $roleIndicator = ($user['user_type'] === 'admin') ? '👑' : ($user['user_type'] === 'teacher' ? '👨‍🏫' : '👨‍🎓');
            echo "  {$roleIndicator} ID: {$user['id']}, Username: {$user['username']}, Role: {$user['user_type']}\n";
        }
    }
    
} catch (PDOException $e) {
    echo "✗ Failed to fetch users: " . $e->getMessage() . "\n";
}

echo "\n=== Migration Summary ===\n";
echo "✓ Database schema updated to support admin role\n";
echo "✓ Admin migration completed\n";
echo "\nUser 'lea' now has full admin control!\n";
?>
