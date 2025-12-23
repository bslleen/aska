# Authentication Troubleshooting Guide

## Current Status ✅
- Database setup working correctly
- AuthProvider updated with Dio + cookie management
- CORS configured for mobile simulators
- All dependencies installed

## Common Issues & Solutions

### 1. Server Not Running
**Problem**: "Address already in use" or server not responding
**Solution**: 
```bash
# Kill any existing PHP servers
pkill -f "php -S"

# Start fresh server
cd backend && php -S localhost:8000
```

### 2. Cookie Storage Path Issues (Mobile Simulators)
**Problem**: Cookies not persisting in mobile environment
**Solution**: Update cookie storage path in AuthProvider

### 3. Network Connectivity
**Problem**: Requests not reaching backend
**Solution**: Check if backend is accessible

## Quick Debug Steps

### Step 1: Test Backend Connection
```bash
curl http://localhost:8000
```

### Step 2: Check AuthProvider Logs
Add this to your Flutter app to see Dio logs:
```dart
// In _initializeDio() method
_dio.interceptors.add(
  LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => print('[DIO] $obj'),
  ),
);
```

### Step 3: Verify Session Cookie
Check if session cookies are being sent with requests:
- Look for `Cookie: PHPSESSID=...` in network logs
- Verify cookies are stored in `.cookies/` directory

### Step 4: Check Database
Verify users can be created:
```bash
php setup_users.php
```

## Expected Flow
1. **Login Request** → Backend sets session → Frontend stores cookie
2. **Profile Edit Request** → Frontend sends cookie → Backend validates session
3. **Update Success** → User profile updated

## If Still Not Working

### Option 1: Fallback to Simple HTTP
If cookie management is complex, we can implement:
- Token-based authentication instead of sessions
- Store tokens in SharedPreferences
- Send tokens in Authorization header

### Option 2: Debug Specific Error
Add error logging to see exact failure point:
```php
// In update_user.php, add after line with session check
error_log("Session check: user_id = " . ($_SESSION['user_id'] ?? 'null'));
error_log("Request method: " . $_SERVER['REQUEST_METHOD']);
error_log("Request data: " . file_get_contents('php://input'));
```

### Option 3: Alternative Cookie Path
Update AuthProvider cookie storage:
```dart
_cookieJar = PersistCookieJar(
  storage: FileStorage('cookies/'), // Use relative path instead
);
```

## Next Steps
1. **Test backend connection**: `curl http://localhost:8000`
2. **Add Dio logging** to see request details
3. **Check if server is running** on port 8000
4. **Try creating a new user** and logging in
5. **Test profile edit** with detailed logging

The authentication fix should work, but these steps will help identify any remaining issues!
