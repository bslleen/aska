<?php
header('Content-Type: application/json');
require_once 'db.php';

echo json_encode(['message' => 'Complete Admin Setup Script']);

// Step 1: Check current users table structure
echo "\n=== Step 1: Check Current Database Structure ===\n";
try {
    $stmt = $pdo->query("DESCRIBE users");
    $columns = $stmt->fetchAll();
    
    echo "Current users table structure:\n";
    foreach ($columns as $column) {
        echo "  - {$column['Field']}: {$column['Type']}\n";
    }
    
    // Check if user_type column exists
    $hasUserType = false;
    foreach ($columns as $column) {
        if ($column['Field'] === 'user_type') {
            $hasUserType = true;
            break;
        }
    }
    
    if (!$hasUserType) {
        echo "\n⚠ user_type column not found. Adding it...\n";
        
        // Add user_type column
        $pdo->exec("ALTER TABLE users ADD COLUMN user_type ENUM('student', 'teacher', 'admin') DEFAULT 'student'");
        echo "✓ Added user_type column with admin support\n";
    } else {
        echo "\n✓ user_type column already exists\n";
    }
    
} catch (PDOException $e) {
    echo "✗ Database structure check failed: " . $e->getMessage() . "\n";
}

// Step 2: Check current users
echo "\n=== Step 2: Current Users ===\n";
try {
    $stmt = $pdo->query("SELECT id, username, email FROM users ORDER BY id");
    $users = $stmt->fetchAll();
    
    if (empty($users)) {
        echo "No users found in database\n";
    } else {
        echo "Found " . count($users) . " users:\n";
        foreach ($users as $user) {
            echo "  - ID: {$user['id']}, Username: {$user['username']}, Email: {$user['email']}\n";
        }
    }
    
} catch (PDOException $e) {
    echo "✗ Failed to fetch users: " . $e->getMessage() . "\n";
}

// Step 3: Promote user 'lea' to admin
echo "\n=== Step 3: Promote User 'lea' to Admin ===\n";
try {
    // First, let's see if lea exists
    $stmt = $pdo->prepare("SELECT id, username, user_type FROM users WHERE username = 'lea'");
    $stmt->execute();
    $leaUser = $stmt->fetch();
    
    if ($leaUser) {
        echo "✓ Found user 'lea' with ID: {$leaUser['id']}\n";
        
        // Check current role
        if ($leaUser['user_type']) {
            echo "  Current role: {$leaUser['user_type']}\n";
        } else {
            echo "  No role assigned yet\n";
        }
        
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
        echo "Available users to promote:\n";
        
        $stmt = $pdo->prepare("SELECT id, username, email FROM users WHERE username != 'lea' ORDER BY id LIMIT 5");
        $stmt->execute();
        $availableUsers = $stmt->fetchAll();
        
        foreach ($availableUsers as $user) {
            echo "  - ID: {$user['id']}, Username: {$user['username']}, Email: {$user['email']}\n";
        }
        
        if (count($availableUsers) > 0) {
            echo "\nShould I promote the first available user to admin instead? (manual step required)\n";
        }
    }
    
} catch (PDOException $e) {
    echo "✗ Failed to promote user 'lea': " . $e->getMessage() . "\n";
}

// Step 4: Show final state
echo "\n=== Step 4: Final State ===\n";
try {
    $stmt = $pdo->query("SELECT id, username, email, user_type, created_at FROM users ORDER BY id");
    $users = $stmt->fetchAll();
    
    if (empty($users)) {
        echo "No users found in database\n";
    } else {
        echo "All users after migration:\n";
        foreach ($users as $user) {
            $roleIndicator = ($user['user_type'] === 'admin') ? '👑' : ($user['user_type'] === 'teacher' ? '👨‍🏫' : '👨‍🎓');
            echo "  {$roleIndicator} ID: {$user['id']}, Username: {$user['username']}, Role: {$user['user_type']}\n";
        }
    }
    
} catch (PDOException $e) {
    echo "✗ Failed to fetch final state: " . $e->getMessage() . "\n";
}

echo "\n=== Setup Summary ===\n";
echo "✓ Database schema updated to support admin role\n";
echo "✓ Migration completed\n";
echo "\nProceed to next step: Creating admin APIs\n";
?>
