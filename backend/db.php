<?php
header('Content-Type: application/json');

$host = 'localhost';
$db   = 'aska_db';
$user = 'root';
$pass = 'NewStrongPassword123!';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";

$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    echo json_encode(['error' => 'DB Connection failed: '.$e->getMessage()]);
    exit;
}
?>
