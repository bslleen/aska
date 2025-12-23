<?php
// Token management utilities

function generateToken($userId) {
    $payload = [
        'user_id' => $userId,
        'iat' => time(),
        'exp' => time() + (7 * 24 * 60 * 60), // 7 days
    ];
    
    // For simplicity, we'll use a base64 encoded token
    // In production, use JWT or a more secure token system
    $tokenData = base64_encode(json_encode($payload));
    $signature = hash_hmac('sha256', $tokenData, 'your-secret-key-here');
    
    return $tokenData . '.' . $signature;
}

function validateToken($token) {
    if (!$token) {
        return false;
    }
    
    $parts = explode('.', $token);
    if (count($parts) !== 2) {
        return false;
    }
    
    list($tokenData, $signature) = $parts;
    
    // Verify signature
    $expectedSignature = hash_hmac('sha256', $tokenData, 'your-secret-key-here');
    if (!hash_equals($expectedSignature, $signature)) {
        return false;
    }
    
    // Decode payload
    $payload = json_decode(base64_decode($tokenData), true);
    if (!$payload) {
        return false;
    }
    
    // Check expiration
    if ($payload['exp'] < time()) {
        return false;
    }
    
    return $payload;
}

function getUserIdFromToken($token) {
    $payload = validateToken($token);
    if (!$payload) {
        return null;
    }
    
    return $payload['user_id'];
}

// ------------------------------
// Token Blacklist Management
// ------------------------------

function isTokenBlacklisted($token) {
    global $pdo;
    
    if (!$token) {
        return true;
    }
    
    $tokenHash = hash('sha256', $token);
    
    try {
        $stmt = $pdo->prepare("SELECT id FROM token_blacklist WHERE token_hash = ?");
        $stmt->execute([$tokenHash]);
        
        return $stmt->fetch() !== false;
    } catch (PDOException $e) {
        error_log("Error checking token blacklist: " . $e->getMessage());
        return false;
    }
}

function blacklistToken($token, $userId) {
    global $pdo;
    
    if (!$token || !$userId) {
        return false;
    }
    
    $tokenHash = hash('sha256', $token);
    
    try {
        $stmt = $pdo->prepare("INSERT IGNORE INTO token_blacklist (token_hash, user_id) VALUES (?, ?)");
        return $stmt->execute([$tokenHash, $userId]);
    } catch (PDOException $e) {
        error_log("Error blacklisting token: " . $e->getMessage());
        return false;
    }
}

function validateTokenWithBlacklist($token) {
    // First check if token is blacklisted
    if (isTokenBlacklisted($token)) {
        return false;
    }
    
    // Then validate normally
    return validateToken($token);
}

function cleanupExpiredTokens() {
    global $pdo;
    
    try {
        // Clean up tokens older than 30 days
        $stmt = $pdo->prepare("DELETE FROM token_blacklist WHERE invalidated_at < DATE_SUB(NOW(), INTERVAL 30 DAY)");
        $stmt->execute();
        
        return $stmt->rowCount();
    } catch (PDOException $e) {
        error_log("Error cleaning up expired tokens: " . $e->getMessage());
        return 0;
    }
}
?>
