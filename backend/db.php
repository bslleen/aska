<?php
$host = 'localhost';
$db   = 'aska_db';
$user = 'root';
$pass = 'NewStrongPassword123!';
$charset = 'utf8mb4';

// Create PDO connection (for new code)
$dsn = "mysql:host=$host;dbname=$db;charset=$charset";

$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    echo json_encode(['error' => 'PDO DB Connection failed: '.$e->getMessage()]);
    exit;
}

// Create mysqli connection (for legacy code that uses $conn)
$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    echo json_encode(['error' => 'mysqli DB Connection failed: '.$conn->connect_error]);
    exit;
}

$conn->set_charset('utf8mb4');

