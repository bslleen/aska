<?php
/**
 * Setup Teacher Selena - Test Data Creation
 * 
 * This script creates:
 * - Teacher "selena" with password "selena1234"
 * - Assigns selena to multiple subjects
 * - Creates test questions for selena's subjects
 * 
 * Run via: php backend/setup_teacher_selena.php
 */

header('Content-Type: application/json');

require 'db.php';

try {
    $changes = [];
    
    // 1. Create categories if they don't exist (for test questions)
    $categories = [
        'Computer Science',
        'Mathematics', 
        'Physics',
        'Chemistry',
        'English',
        'History'
    ];
    
    $categoryMap = [];
    foreach ($categories as $categoryName) {
        try {
            $stmt = $pdo->prepare("SELECT id FROM categories WHERE name = ?");
            $stmt->execute([$categoryName]);
            $existing = $stmt->fetch();
            
            if ($existing) {
                $categoryMap[$categoryName] = $existing['id'];
                $changes[] = "Category '$categoryName' exists (ID: {$existing['id']})";
            } else {
                $stmt = $pdo->prepare("INSERT INTO categories (name, description) VALUES (?, ?)");
                $stmt->execute([$categoryName, "$categoryName subject questions"]);
                $categoryId = $pdo->lastInsertId();
                $categoryMap[$categoryName] = $categoryId;
                $changes[] = "Created category '$categoryName' (ID: $categoryId)";
            }
        } catch (PDOException $e) {
            $changes[] = "Error with category '$categoryName': " . $e->getMessage();
        }
    }
    
    // 2. Create or update teacher "selena"
    $selenaPasswordHash = password_hash('selena1234', PASSWORD_DEFAULT);
    
    // Check if selena already exists
    $stmt = $pdo->prepare("SELECT id, user_type FROM users WHERE username = 'selena'");
    $stmt->execute();
    $existingSelena = $stmt->fetch();
    
    $selenaId = null;
    if ($existingSelena) {
        $selenaId = $existingSelena['id'];
        if ($existingSelena['user_type'] !== 'teacher') {
            // Update to teacher
            $stmt = $pdo->prepare("UPDATE users SET user_type = 'teacher', password_hash = ? WHERE id = ?");
            $stmt->execute([$selenaPasswordHash, $selenaId]);
            $changes[] = "Updated user 'selena' to teacher role";
        } else {
            // Just update password
            $stmt = $pdo->prepare("UPDATE users SET password_hash = ? WHERE id = ?");
            $stmt->execute([$selenaPasswordHash, $selenaId]);
            $changes[] = "Updated password for existing teacher 'selena'";
        }
    } else {
        // Create new teacher
        $stmt = $pdo->prepare("
            INSERT INTO users (username, email, password_hash, full_name, user_type, bio, trust_score)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            'selena',
            'selena@school.edu',
            $selenaPasswordHash,
            'Ms. Selena Thompson',
            'teacher',
            'Experienced teacher specializing in multiple subjects',
            100
        ]);
        $selenaId = $pdo->lastInsertId();
        $changes[] = "Created new teacher 'selena' (ID: $selenaId)";
    }
    
    // 3. Assign selena to categories
    $assignedCategories = ['Computer Science', 'Mathematics', 'English'];
    
    foreach ($assignedCategories as $categoryName) {
        if (!isset($categoryMap[$categoryName])) {
            $changes[] = "Skipping assignment - category '$categoryName' not found";
            continue;
        }
        
        $categoryId = $categoryMap[$categoryName];
        
        // Check if assignment exists
        $stmt = $pdo->prepare("SELECT id FROM category_teachers WHERE category_id = ? AND teacher_id = ?");
        $stmt->execute([$categoryId, $selenaId]);
        
        if ($stmt->fetch()) {
            $changes[] = "Selena already assigned to '$categoryName'";
        } else {
            $stmt = $pdo->prepare("INSERT INTO category_teachers (category_id, teacher_id) VALUES (?, ?)");
            $stmt->execute([$categoryId, $selenaId]);
            $changes[] = "Assigned Selena to category '$categoryName'";
        }
    }
    
    // 4. Create test students if they don't exist
    $testStudents = [
        [
            'username' => 'test_alice',
            'password' => 'test123',
            'full_name' => 'Alice Test'
        ],
        [
            'username' => 'test_bob', 
            'password' => 'test123',
            'full_name' => 'Bob Test'
        ]
    ];
    
    $studentIds = [];
    foreach ($testStudents as $student) {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
        $stmt->execute([$student['username']]);
        $existing = $stmt->fetch();
        
        if ($existing) {
            $studentIds[$student['username']] = $existing['id'];
            $changes[] = "Student '{$student['username']}' already exists";
        } else {
            $passwordHash = password_hash($student['password'], PASSWORD_DEFAULT);
            $stmt = $pdo->prepare("
                INSERT INTO users (username, email, password_hash, full_name, user_type, trust_score)
                VALUES (?, ?, ?, ?, 'student', ?)
            ");
            $stmt->execute([
                $student['username'],
                $student['username'] . '@test.edu',
                $passwordHash,
                $student['full_name'],
                50
            ]);
            $studentIds[$student['username']] = $pdo->lastInsertId();
            $changes[] = "Created student '{$student['username']}'";
        }
    }
    
    // 5. Create test questions for Selena's subjects
    $testQuestions = [
        // Computer Science questions
        [
            'title' => 'What is the difference between Java and Python?',
            'content' => 'I am new to programming and wondering which language to learn first. What are the main differences between Java and Python?',
            'category' => 'Computer Science',
            'author' => 'test_alice'
        ],
        [
            'title' => 'How do I debug my code effectively?',
            'content' => 'I spend hours trying to find bugs in my code. What are some best practices for debugging?',
            'category' => 'Computer Science',
            'author' => 'test_bob'
        ],
        [
            'title' => 'What is object-oriented programming?',
            'content' => 'Can someone explain the four pillars of OOP with simple examples?',
            'category' => 'Computer Science',
            'author' => 'test_alice'
        ],
        [
            'title' => 'How to optimize SQL queries?',
            'content' => 'My database queries are running slow. What techniques can I use to improve performance?',
            'category' => 'Computer Science',
            'author' => 'test_bob'
        ],
        
        // Mathematics questions
        [
            'title' => 'Why do we need calculus?',
            'content' => 'I am struggling to understand the practical applications of calculus in real life.',
            'category' => 'Mathematics',
            'author' => 'test_bob'
        ],
        [
            'title' => 'How to understand probability better?',
            'content' => 'Probability confuses me. Can someone explain conditional probability with examples?',
            'category' => 'Mathematics',
            'author' => 'test_alice'
        ],
        [
            'title' => 'What are the most useful math formulas?',
            'content' => 'I want to know which math formulas I should memorize for everyday problem solving.',
            'category' => 'Mathematics',
            'author' => 'test_bob'
        ],
        
        // English questions
        [
            'title' => 'How to improve my essay writing?',
            'content' => 'I have trouble organizing my thoughts in essays. What structure works best?',
            'category' => 'English',
            'author' => 'test_alice'
        ],
        [
            'title' => 'What books should I read to improve vocabulary?',
            'content' => 'I want to expand my English vocabulary. What classic books do you recommend?',
            'category' => 'English',
            'author' => 'test_bob'
        ],
        [
            'title' => 'Difference between formal and informal writing?',
            'content' => 'When should I use formal language vs informal in my writing?',
            'category' => 'English',
            'author' => 'test_alice'
        ]
    ];
    
    $questionsCreated = 0;
    foreach ($testQuestions as $question) {
        $author = $question['author'];
        $category = $question['category'];
        unset($question['author'], $question['category']);
        
        if (!isset($studentIds[$author]) || !isset($categoryMap[$category])) {
            $changes[] = "Skipping question '{$question['title']}' - missing data";
            continue;
        }
        
        // Check if question already exists (by title)
        $stmt = $pdo->prepare("SELECT id FROM posts WHERE title = ?");
        $stmt->execute([$question['title']]);
        if ($stmt->fetch()) {
            $changes[] = "Question '{$question['title']}' already exists, skipping";
            continue;
        }
        
        try {
            $stmt = $pdo->prepare("
                INSERT INTO posts (user_id, category_id, title, content, created_at)
                VALUES (?, ?, ?, ?, NOW())
            ");
            $stmt->execute([
                $studentIds[$author],
                $categoryMap[$category],
                $question['title'],
                $question['content']
            ]);
            $questionsCreated++;
            $changes[] = "Created question: '{$question['title']}' in $category";
        } catch (PDOException $e) {
            $changes[] = "Error creating question: " . $e->getMessage();
        }
    }
    
    // 6. Verify the setup by running get_teacher_questions query
    $stmt = $pdo->prepare("
        SELECT 
            c.name as category_name,
            COUNT(p.id) as question_count
        FROM categories c
        LEFT JOIN category_teachers ct ON c.id = ct.category_id AND ct.teacher_id = ?
        LEFT JOIN posts p ON c.id = p.category_id
        WHERE ct.teacher_id = ?
        GROUP BY c.id, c.name
        ORDER BY c.name
    ");
    $stmt->execute([$selenaId, $selenaId]);
    $categoryStats = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $totalQuestions = array_sum(array_column($categoryStats, 'question_count'));
    
    // Output summary
    echo json_encode([
        'success' => true,
        'message' => 'Teacher Selena setup completed successfully!',
        'summary' => [
            'teacher_id' => $selenaId,
            'teacher_username' => 'selena',
            'teacher_password' => 'selena1234',
            'assigned_categories' => $assignedCategories,
            'test_questions_created' => $questionsCreated,
            'total_questions_for_selena' => $totalQuestions
        ],
        'category_breakdown' => $categoryStats,
        'test_accounts' => [
            'teacher' => [
                'username' => 'selena',
                'password' => 'selena1234',
                'user_type' => 'teacher'
            ],
            'students' => [
                ['username' => 'test_alice', 'password' => 'test123'],
                ['username' => 'test_bob', 'password' => 'test123']
            ]
        ],
        'changes' => $changes
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Setup failed: ' . $e->getMessage()
    ]);
}
?>

