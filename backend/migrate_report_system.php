<?php
// Migrate Report System - Create tables for reports
header('Content-Type: application/json');
require_once 'db.php';

// Check if reports table already exists
$checkTable = $conn->query("SHOW TABLES LIKE 'reports'");
if ($checkTable->num_rows > 0) {
    echo json_encode(['success' => true, 'message' => 'Reports table already exists']);
    exit;
}

// Create reports table
$sql = "
CREATE TABLE IF NOT EXISTS reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    report_type ENUM('post', 'reply') NOT NULL,
    target_id INT NOT NULL COMMENT 'post_id or reply_id',
    reporter_id INT NOT NULL,
    reason VARCHAR(100) NOT NULL COMMENT 'wrong_info, not_related, disrespectful, other',
    details TEXT NULL COMMENT 'Additional details for other reason',
    status ENUM('pending', 'dismissed', 'resolved') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dismissed_by INT NULL,
    dismissed_at TIMESTAMP NULL,
    INDEX idx_target (report_type, target_id),
    INDEX idx_status (status),
    INDEX idx_reporter (reporter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
";

if ($conn->query($sql)) {
    echo json_encode(['success' => true, 'message' => 'Reports table created successfully']);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to create reports table: ' . $conn->error]);
}

