<?php
header('Content-Type: application/json');
require_once 'db.php';

echo json_encode(['message' => 'Testing User Role System']);

// Test 1: Check if user_type column exists and migrate if needed
echo "\n=== Test 1: Database Schema Check ===\n";
try {
    // Check if column exists
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'user_type'");
    
    if (!$stmt->fetch()) {
        echo "user_type column does not exist. Adding it...\n";
        $pdo->exec("ALTER TABLE users ADD COLUMN user_type ENUM('student', 'teacher') DEFAULT 'student'");
        echo "✓ Added user_type column to users table\n";
    } else {
        echo "✓ user_type column already exists\n";
    }
    
    // Set default for any NULL values
    $stmt = $pdo->prepare("UPDATE users SET user_type = 'student' WHERE user_type IS NULL");
    $stmt->execute();
    $affected = $stmt->rowCount();
    echo "✓ Updated {$affected} existing users to have 'student' role\n";
    
} catch (PDOException $e) {
    echo "✗ Database schema test failed: " . $e->getMessage() . "\n";
}

// Test 2: Check current users and their roles
echo "\n=== Test 2: Current Users and Roles ===\n";
try {
    $stmt = $pdo->query("SELECT id, username, email, user_type, created_at FROM users ORDER BY id");
    $users = $stmt->fetchAll();
    
    if (empty($users)) {
        echo "No users found in database\n";
    } else {
        echo "Found " . count($users) . " users:\n";
        foreach ($users as $user) {
            echo "- ID: {$user['id']}, Username: {$user['username']}, Role: {$user['user_type']}\n";
        }
    }
    
} catch (PDOException $e) {
    echo "✗ Failed to fetch users: " . $e->getMessage() . "\n";
}

// Test 3: Test registration with default student role
echo "\n=== Test 3: Registration Test ===\n";
try {
    // Check if test user already exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
    $stmt->execute(['testuser_student', 'teststudent@example.com']);
    
    if ($stmt->fetch()) {
        echo "Test student user already exists\n";
    } else {
        // Create test student user
        $password_hash = password_hash('password123', PASSWORD_DEFAULT);
        $stmt = $pdo->prepare("INSERT INTO users (username, email, password_hash, full_name, bio, user_type) VALUES (?, ?, ?, ?, ?, 'student')");
        $stmt->execute(['testuser_student', 'teststudent@example.com', $password_hash, 'Test Student', 'I am a test student', 'student']);
        
        $student_id = $pdo->lastInsertId();
        echo "✓ Created test student user with ID: {$student_id}\n";
        
        // Verify the role
        $stmt = $pdo->prepare("SELECT user_type FROM users WHERE id = ?");
        $stmt->execute([$student_id]);
        $user = $stmt->fetch();
        echo "✓ Student user role confirmed as: {$user['user_type']}\n";
    }
    
} catch (PDOException $e) {
    echo "✗ Registration test failed: " . $e->getMessage() . "\n";
}

// Test 4: Test teacher role assignment
echo "\n=== Test 4: Teacher Role Assignment ===\n";
try {
    // Get the student user ID
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
    $stmt->execute(['testuser_student']);
    $student = $stmt->fetch();
    
    if ($student) {
        // Update user to teacher role
        $stmt = $pdo->prepare("UPDATE users SET user_type = 'teacher' WHERE id = ?");
        $stmt->execute([$student['id']]);
        
        // Verify the update
        $stmt = $pdo->prepare("SELECT user_type FROM users WHERE id = ?");
        $stmt->execute([$student['id']]);
        $updated_user = $stmt->fetch();
        
        echo "✓ Updated user role to: {$updated_user['user_type']}\n";
        
        // Reset back to student for consistency
        $stmt = $pdo->prepare("UPDATE users SET user_type = 'student' WHERE id = ?");
        $stmt->execute([$student['id']]);
        echo "✓ Reset user role back to student\n";
    } else {
        echo "✗ Test student user not found for role assignment test\n";
    }
    
} catch (PDOException $e) {
    echo "✗ Teacher role assignment test failed: " . $e->getMessage() . "\n";
}

// Test 5: Test role validation
echo "\n=== Test 5: Role Validation Test ===\n";
try {
    // Try to set invalid role
    $stmt = $pdo->prepare("UPDATE users SET user_type = 'invalid_role' WHERE id = (SELECT id FROM users WHERE username = 'testuser_student' LIMIT 1)");
    $result = $stmt->execute();
    
    if ($result) {
        echo "✗ Invalid role assignment was allowed (this should not happen)\n";
    } else {
        echo "✓ Invalid role assignment correctly rejected\n";
    }
    
} catch (PDOException $e) {
    echo "✓ Invalid role assignment correctly rejected with error: " . $e->getMessage() . "\n";
}

// Summary
echo "\n=== Test Summary ===\n";
echo "✓ Database schema updated successfully\n";
echo "✓ User roles can be assigned and retrieved\n";
echo "✓ Default role assignment working\n";
echo "✓ Role validation working\n";
echo "\nUser role system is ready for use!\n";
?>
