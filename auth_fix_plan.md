# Authentication Fix Plan

## Problem
User gets "user not authenticated" when trying to edit profile due to session cookie management issues between Flutter frontend and PHP backend.

## Root Cause
- PHP backend uses sessions (`$_SESSION['user_id']`) to track authenticated users
- Flutter HTTP client doesn't send session cookies with requests
- Backend doesn't recognize authenticated requests

## Solution Steps

### 1. Add HTTP Cookie Support
- Install `cookie_jar` and `dio` packages for better HTTP cookie management
- Configure persistent cookie storage
- Update AuthProvider to use cookie-aware HTTP client

### 2. Update AuthProvider Implementation
- Replace direct `http` calls with cookie-aware HTTP client
- Ensure session cookies are sent with authenticated requests
- Add proper error handling for session expiry

### 3. Backend Session Configuration
- Update PHP backend to handle CORS with credentials
- Add proper session cookie configuration
- Ensure session persistence across requests

### 4. Testing & Validation
- Test login → profile edit flow
- Verify session persistence across app restarts
- Handle session expiry gracefully

## Files to Modify
1. `frontend/pubspec.yaml` - Add dependencies
2. `frontend/lib/auth_provider.dart` - Implement cookie management
3. `backend/index.php` - Update CORS configuration
4. `frontend/lib/profile_modal.dart` - Ensure proper error handling

## Expected Outcome
- User can successfully edit profile after login
- Session persists across app sessions
- Proper error handling for authentication failures
