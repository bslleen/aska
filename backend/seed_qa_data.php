<?php
/**
 * Q&A System Seed Data Script
 * 
 * This script creates sample data for testing the Q&A system:
 * - Categories (Computer Science, Math, Physics, etc.)
 * - Teachers with subject assignments
 * - Students
 * - Sample questions and answers
 * 
 * Run via: php backend/seed_qa_data.php
 */

header('Content-Type: application/json');

require 'db.php';

try {
    $changes = [];

    // 1. Create categories if they don't exist
    $categories = [
        ['name' => 'Computer Science', 'description' => 'Programming, algorithms, data structures'],
        ['name' => 'Mathematics', 'description' => 'Algebra, Calculus, Statistics'],
        ['name' => 'Physics', 'description' => 'Mechanics, Thermodynamics, Electromagnetism'],
        ['name' => 'Chemistry', 'description' => 'Organic, Inorganic, Physical Chemistry'],
        ['name' => 'Biology', 'description' => 'Cell biology, Genetics, Ecology'],
        ['name' => 'English', 'description' => 'Literature, Writing, Grammar'],
        ['name' => 'History', 'description' => 'World History, Ancient Civilizations'],
        ['name' => 'Art', 'description' => 'Drawing, Painting, Digital Art'],
    ];

    $categoryMap = [];
    foreach ($categories as $category) {
        try {
            $stmt = $pdo->prepare("SELECT id FROM categories WHERE name = ?");
            $stmt->execute([$category['name']]);
            $existing = $stmt->fetch();
            
            if ($existing) {
                $categoryMap[$category['name']] = $existing['id'];
                $changes[] = "Category '{$category['name']}' already exists (ID: {$existing['id']})";
            } else {
                $stmt = $pdo->prepare("INSERT INTO categories (name, description) VALUES (?, ?)");
                $stmt->execute([$category['name'], $category['description']]);
                $categoryId = $pdo->lastInsertId();
                $categoryMap[$category['name']] = $categoryId;
                $changes[] = "Created category '{$category['name']}' (ID: $categoryId)";
            }
        } catch (PDOException $e) {
            $changes[] = "Error with category '{$category['name']}': " . $e->getMessage();
        }
    }

    // 2. Create teachers with hashed passwords (using password_hash column)
    $teachers = [
        [
            'username' => 'prof_smith',
            'email' => 'smith@school.edu',
            'password_hash' => password_hash('teacher123', PASSWORD_DEFAULT),
            'full_name' => 'Dr. John Smith',
            'user_type' => 'teacher',
            'bio' => 'Computer Science professor with 15 years of experience',
            'subjects' => ['Computer Science']
        ],
        [
            'username' => 'dr_jones',
            'email' => 'jones@school.edu',
            'password_hash' => password_hash('teacher123', PASSWORD_DEFAULT),
            'full_name' => 'Dr. Sarah Jones',
            'user_type' => 'teacher',
            'bio' => 'Mathematics PhD, specializing in calculus and statistics',
            'subjects' => ['Mathematics', 'Computer Science']
        ],
        [
            'username' => 'prof_wilson',
            'email' => 'wilson@school.edu',
            'password_hash' => password_hash('teacher123', PASSWORD_DEFAULT),
            'full_name' => 'Prof. Michael Wilson',
            'user_type' => 'teacher',
            'bio' => 'Physics professor, research in quantum mechanics',
            'subjects' => ['Physics']
        ],
    ];

    $teacherIds = [];
    foreach ($teachers as $teacher) {
        $subjects = $teacher['subjects'];
        $passwordHash = $teacher['password_hash'];
        unset($teacher['subjects'], $teacher['password_hash']);
        
        try {
            $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
            $stmt->execute([$teacher['username']]);
            $existing = $stmt->fetch();
            
            if ($existing) {
                $teacherIds[$teacher['username']] = $existing['id'];
                $changes[] = "Teacher '{$teacher['username']}' already exists (ID: {$existing['id']})";
            } else {
                $stmt = $pdo->prepare("
                    INSERT INTO users (username, email, password_hash, full_name, user_type, bio, trust_score)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ");
                $stmt->execute([
                    $teacher['username'],
                    $teacher['email'],
                    $passwordHash,
                    $teacher['full_name'],
                    $teacher['user_type'],
                    $teacher['bio'],
                    100 // Max trust score for teachers
                ]);
                $teacherId = $pdo->lastInsertId();
                $teacherIds[$teacher['username']] = $teacherId;
                $changes[] = "Created teacher '{$teacher['username']}' (ID: $teacherId)";
                
                // Assign teacher to categories
                foreach ($subjects as $subject) {
                    if (isset($categoryMap[$subject])) {
                        try {
                            $stmt = $pdo->prepare("
                                INSERT INTO category_teachers (category_id, teacher_id)
                                VALUES (?, ?)
                                ON DUPLICATE KEY UPDATE assigned_at = CURRENT_TIMESTAMP
                            ");
                            $stmt->execute([$categoryMap[$subject], $teacherId]);
                            $changes[] = "  - Assigned to category '$subject'";
                        } catch (PDOException $e) {
                            $changes[] = "  - Error assigning to '$subject': " . $e->getMessage();
                        }
                    }
                }
            }
        } catch (PDOException $e) {
            $changes[] = "Error with teacher '{$teacher['username']}': " . $e->getMessage();
        }
    }

    // 3. Create students (using password_hash column)
    $students = [
        [
            'username' => 'student_alice',
            'email' => 'alice@student.edu',
            'password_hash' => password_hash('student123', PASSWORD_DEFAULT),
            'full_name' => 'Alice Johnson',
            'bio' => 'Computer Science major, interested in AI'
        ],
        [
            'username' => 'student_bob',
            'email' => 'bob@student.edu',
            'password_hash' => password_hash('student123', PASSWORD_DEFAULT),
            'full_name' => 'Bob Williams',
            'bio' => 'Mathematics student, love statistics'
        ],
        [
            'username' => 'student_carol',
            'email' => 'carol@student.edu',
            'password_hash' => password_hash('student123', PASSWORD_DEFAULT),
            'full_name' => 'Carol Davis',
            'bio' => 'Physics enthusiast, future researcher'
        ],
        [
            'username' => 'student_david',
            'email' => 'david@student.edu',
            'password_hash' => password_hash('student123', PASSWORD_DEFAULT),
            'full_name' => 'David Brown',
            'bio' => 'Full-stack developer, JavaScript lover'
        ],
        [
            'username' => 'student_emma',
            'email' => 'emma@student.edu',
            'password_hash' => password_hash('student123', PASSWORD_DEFAULT),
            'full_name' => 'Emma Wilson',
            'bio' => 'Data science student, Python developer'
        ],
    ];

    $studentIds = [];
    foreach ($students as $student) {
        $passwordHash = $student['password_hash'];
        unset($student['password_hash']);
        
        try {
            $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
            $stmt->execute([$student['username']]);
            $existing = $stmt->fetch();
            
            if ($existing) {
                $studentIds[$student['username']] = $existing['id'];
                $changes[] = "Student '{$student['username']}' already exists (ID: {$existing['id']})";
            } else {
                $stmt = $pdo->prepare("
                    INSERT INTO users (username, email, password_hash, full_name, user_type, bio, trust_score)
                    VALUES (?, ?, ?, ?, 'student', ?, ?)
                ");
                $stmt->execute([
                    $student['username'],
                    $student['email'],
                    $passwordHash,
                    $student['full_name'],
                    $student['bio'],
                    50 // Starting trust score
                ]);
                $studentId = $pdo->lastInsertId();
                $studentIds[$student['username']] = $studentId;
                $changes[] = "Created student '{$student['username']}' (ID: $studentId)";
            }
        } catch (PDOException $e) {
            $changes[] = "Error with student '{$student['username']}': " . $e->getMessage();
        }
    }

    // 4. Create sample questions
    $questions = [
        [
            'title' => 'How does inheritance work in OOP?',
            'content' => 'I am trying to understand inheritance in object-oriented programming. Can someone explain the concept with a simple example? I am confused about when to use extends vs implements in Java.',
            'author' => 'student_alice',
            'category' => 'Computer Science'
        ],
        [
            'title' => 'What is the difference between stack and queue?',
            'content' => 'I keep mixing up stacks and queues. Can someone explain the key differences and when to use each data structure?',
            'author' => 'student_david',
            'category' => 'Computer Science'
        ],
        [
            'title' => 'How to solve quadratic equations?',
            'content' => 'I am struggling with solving quadratic equations. Can someone explain the quadratic formula and how to apply it?',
            'author' => 'student_bob',
            'category' => 'Mathematics'
        ],
        [
            'title' => 'What is the difference between speed and velocity?',
            'content' => 'In physics class, we learned about speed and velocity. They seem similar but our teacher says they are different. Can someone clarify?',
            'author' => 'student_carol',
            'category' => 'Physics'
        ],
        [
            'title' => 'How to write a recursive function?',
            'content' => 'I am having trouble understanding recursion. Can someone provide a simple example and explain the base case?',
            'author' => 'student_emma',
            'category' => 'Computer Science'
        ],
    ];

    $questionIds = [];
    foreach ($questions as $question) {
        $author = $question['author'];
        $category = $question['category'];
        unset($question['author'], $question['category']);
        
        try {
            if (!isset($studentIds[$author]) || !isset($categoryMap[$category])) {
                $changes[] = "Skipping question '{$question['title']}' - missing author or category";
                continue;
            }
            
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
            $questionId = $pdo->lastInsertId();
            $questionIds[] = $questionId;
            $changes[] = "Created question '{$question['title']}' (ID: $questionId)";
        } catch (PDOException $e) {
            $changes[] = "Error creating question: " . $e->getMessage();
        }
    }

    // 5. Create sample answers (mix of public and private)
    $answers = [
        [
            'post_id' => 1, // First question (OOP inheritance)
            'content' => 'Inheritance allows a class to inherit properties and methods from another class. In Java, use "extends" for class inheritance. For example, if you have a "Vehicle" class, you can create a "Car" class that extends Vehicle, and Car will have all Vehicle\'s methods plus its own.',
            'author' => 'prof_smith',
            'visibility' => 'public',
            'target_student_id' => null
        ],
        [
            'post_id' => 1,
            'content' => 'Great question Alice! One thing to add: remember that Java supports single inheritance only (one parent class), but you can implement multiple interfaces. This is different from languages like C++ that allow multiple inheritance.',
            'author' => 'dr_jones',
            'visibility' => 'public',
            'target_student_id' => null
        ],
        [
            'post_id' => 1,
            'content' => 'Alice, if you want more help with this specific concept, I can schedule a private session to go over it in detail.',
            'author' => 'prof_smith',
            'visibility' => 'private',
            'target_student_id' => $studentIds['student_alice']
        ],
        [
            'post_id' => 2, // Stack vs Queue
            'content' => 'Think of a stack like a stack of plates - last one in is first one out (LIFO). A queue is like a line of people - first one in is first one out (FIFO). Use stack for undo operations, queue for task scheduling.',
            'author' => 'prof_smith',
            'visibility' => 'public',
            'target_student_id' => null
        ],
        [
            'post_id' => 3, // Quadratic equations
            'content' => 'The quadratic formula is: x = (-b ± √(b² - 4ac)) / 2a. Where ax² + bx + c = 0. The ± means there are usually two solutions!',
            'author' => 'dr_jones',
            'visibility' => 'public',
            'target_student_id' => null
        ],
        [
            'post_id' => 4, // Speed vs Velocity
            'content' => 'Speed is how fast something is moving (scalar - just magnitude). Velocity includes direction (vector - magnitude + direction). If you drive 60 mph north, your speed is 60 and velocity is 60 mph north.',
            'author' => 'prof_wilson',
            'visibility' => 'public',
            'target_student_id' => null
        ],
        [
            'post_id' => 5, // Recursive function
            'content' => 'A recursive function calls itself. The base case stops the recursion to prevent infinite loops. Example: function factorial(n) { if (n <= 1) return 1; return n * factorial(n-1); }',
            'author' => 'prof_smith',
            'visibility' => 'public',
            'target_student_id' => null
        ],
    ];

    foreach ($answers as $answer) {
        $postId = $answer['post_id'];
        $author = $answer['author'];
        $targetStudentId = $answer['target_student_id'];
        unset($answer['post_id'], $answer['author'], $answer['target_student_id']);
        
        try {
            if (!isset($teacherIds[$author])) {
                $changes[] = "Skipping answer - teacher '$author' not found";
                continue;
            }
            
            $stmt = $pdo->prepare("
                INSERT INTO answers (post_id, user_id, content, visibility, target_student_id, created_at)
                VALUES (?, ?, ?, ?, ?, NOW())
            ");
            $stmt->execute([
                $postId,
                $teacherIds[$author],
                $answer['content'],
                $answer['visibility'],
                $targetStudentId
            ]);
            $changes[] = "Created answer to post $postId by $author (visibility: {$answer['visibility']})";
        } catch (PDOException $e) {
            $changes[] = "Error creating answer: " . $e->getMessage();
        }
    }

    // 6. Add some votes
    try {
        // Get all posts and answers
        $stmt = $pdo->query("SELECT id FROM posts");
        $posts = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        $stmt = $pdo->query("SELECT id FROM answers");
        $answers = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        // Add votes to posts
        foreach ($posts as $postId) {
            $voteCount = rand(1, 5);
            $stmt = $pdo->prepare("UPDATE posts SET votes = ? WHERE id = ?");
            $stmt->execute([$voteCount, $postId]);
        }
        
        // Add votes to answers
        foreach ($answers as $answerId) {
            $voteCount = rand(0, 3);
            $stmt = $pdo->prepare("UPDATE answers SET votes = ? WHERE id = ?");
            $stmt->execute([$voteCount, $answerId]);
        }
        
        $changes[] = "Added votes to posts and answers";
    } catch (PDOException $e) {
        $changes[] = "Error adding votes: " . $e->getMessage();
    }

    // Summary
    echo json_encode([
        'success' => true,
        'message' => 'Q&A System seed data created successfully!',
        'summary' => [
            'categories_created' => count($categoryMap),
            'teachers_created' => count($teacherIds),
            'students_created' => count($studentIds),
            'questions_created' => count($questionIds),
            'answers_created' => count($answers)
        ],
        'test_accounts' => [
            'teachers' => [
                ['username' => 'prof_smith', 'password' => 'teacher123', 'subjects' => 'Computer Science'],
                ['username' => 'dr_jones', 'password' => 'teacher123', 'subjects' => 'Mathematics, Computer Science'],
                ['username' => 'prof_wilson', 'password' => 'teacher123', 'subjects' => 'Physics']
            ],
            'students' => [
                ['username' => 'student_alice', 'password' => 'student123'],
                ['username' => 'student_bob', 'password' => 'student123'],
                ['username' => 'student_carol', 'password' => 'student123'],
                ['username' => 'student_david', 'password' => 'student123'],
                ['username' => 'student_emma', 'password' => 'student123']
            ],
            'admin' => [
                'username' => 'lea',
                'password' => 'lea123'
            ]
        ],
        'changes' => $changes
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Seed data creation failed: ' . $e->getMessage()
    ]);
}
?>

