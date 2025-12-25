<?php
header('Content-Type: application/json');

require 'db.php';

try {
    $sql = "SELECT 
                c.id, 
                c.name,
                GROUP_CONCAT(u.username ORDER BY u.username) as teacher_names,
                GROUP_CONCAT(ct.teacher_id ORDER BY ct.assigned_at) as teacher_ids,
                GROUP_CONCAT(ct.assigned_at ORDER BY ct.assigned_at) as assigned_dates
            FROM categories c
            LEFT JOIN category_teachers ct ON c.id = ct.category_id
            LEFT JOIN users u ON ct.teacher_id = u.id
            GROUP BY c.id, c.name
            ORDER BY c.name ASC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Process the results to make teacher info more usable
    foreach ($categories as &$category) {
        if ($category['teacher_names']) {
            $teacherNames = explode(',', $category['teacher_names']);
            $teacherIds = explode(',', $category['teacher_ids']);
            $assignedDates = explode(',', $category['assigned_dates']);
            
            $teachers = [];
            for ($i = 0; $i < count($teacherNames); $i++) {
                $teachers[] = [
                    'id' => intval($teacherIds[$i]),
                    'username' => $teacherNames[$i],
                    'assigned_at' => $assignedDates[$i]
                ];
            }
            $category['teachers'] = $teachers;
        } else {
            $category['teachers'] = [];
        }
        
        // Remove the concatenated fields
        unset($category['teacher_names']);
        unset($category['teacher_ids']);
        unset($category['assigned_dates']);
    }

    echo json_encode($categories);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
