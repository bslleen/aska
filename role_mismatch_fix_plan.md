# Role Mismatch Fix Plan

## Problem Analysis
User "lea" is an admin in the database but appears as a student in the UI without admin privileges.

## Root Cause
The `backend/login.php` file is not selecting the `user_type` field when fetching user data during login. This means:
- Database has correct role: lea = admin ✅
- Login API returns user data without user_type ❌
- Frontend receives incomplete user data ❌
- UI shows student instead of admin ❌

## Files to Fix
1. **backend/login.php** - Add `user_type` to SELECT statement

## Step-by-Step Plan

### Step 1: Fix Login Endpoint
- Edit `backend/login.php`
- Add `user_type` to the SELECT query in both username and email login paths
- Ensure the field is included in the response JSON

### Step 2: Test the Fix
- Run the admin system test to verify lea is admin in database
- Test login flow to ensure user_type is returned
- Verify admin dashboard is accessible after login

### Step 3: Verify UI Changes
- Login as "lea" 
- Check if admin crown icon (👑) appears
- Verify admin dashboard is accessible
- Confirm role-based UI elements work correctly

## Expected Outcome
After the fix:
- User "lea" will log in with admin role preserved
- Admin crown icon will appear in the UI
- Admin dashboard will be accessible
- All admin privileges will be functional
