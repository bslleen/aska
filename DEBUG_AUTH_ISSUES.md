# Debugging Authentication Issues

## Quick Debugging Steps

### 1. Verify Backend is Running
```bash
# Check if PHP server is running
curl http://localhost:8000
```

### 2. Test Login Endpoint Manually
```bash
curl -X POST http://localhost:8000/login.php \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass"}'
```

### 3. Test Profile Update with Token
```bash
# First get a valid token from login, then test update
curl -X POST http://localhost:8000/update_user.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"username":"newusername"}'
```

### 4. Check Flutter App Logs
Add this debug code to your AuthProvider to see what's happening:

```dart
// In updateUser method, add before the HTTP request:
print('Auth token: ${_user?.authToken}');
print('Headers: {\"Authorization\": \"Bearer ${_user?.authToken}\"}');

// After getting response:
print('Response status: ${response.statusCode}');
print('Response body: ${response.body}');
```

### 5. Common Issues & Solutions

#### Issue: Token Validation Fails
**Check token_utils.php** - Ensure the signature verification works
**Solution**: Verify the secret key is consistent

#### Issue: Authorization Header Not Sent
**Check AuthProvider** - Ensure Bearer token is in the headers
**Solution**: Verify header format: `Authorization: Bearer <token>`

#### Issue: Server Not Receiving Requests
**Check network connectivity** - Ensure backend is running on port 8000
**Solution**: Restart PHP server

#### Issue: CORS Issues
**Check all PHP files** - Ensure CORS headers are set correctly
**Solution**: Already fixed for mobile simulators

### 6. Force Fresh Start
```bash
# Clear any cached data
cd frontend
flutter clean
flutter pub get

# Restart backend
pkill -f "php -S"
cd backend
php -S localhost:8000
```

### 7. Verify Token Format
Your token should look like: `base64data.signature`
Example: `eyJ1c2VyX2lkIjoxLCJpYXQiOjE2ODMyNTYzMDAsImV4cCI6MTY4Mzg2MjMwMH0.abc123hash`

### 8. Test with Sample Data
Create a test user manually and verify the complete flow:
1. Register new user → Should get token
2. Login with existing user → Should get token  
3. Use token to update profile → Should succeed
4. Restart app → Should remember user

## Most Likely Issues
1. **Server not running** - Check if localhost:8000 responds
2. **Token not being sent** - Check Authorization header in network requests
3. **Token validation failing** - Check token_utils.php logic
4. **Caching old code** - Force clean rebuild

## Next Steps
1. Run the manual curl tests above
2. Add debug logging to see what's happening
3. Check if the backend is actually receiving your requests
4. Verify the token format and validation logic

Let me know what you find from these debugging steps!
