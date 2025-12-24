# User Role Update Plan

## Objective
Update the user table to support two user types: 'teacher' and 'student', where:
- Students are the default user type when registering
- Teachers need to be assigned manually (possibly by admin or through a separate process)

## Current Analysis
- **Users table structure**: Contains id, username, email, password_hash, full_name, bio, created_at, updated_at
- **Registration process**: Creates users with username, email, password_hash, full_name, bio
- **Update process**: Allows updating user profile information but no role management

## Implementation Plan

### Phase 1: Database Schema Updates
1. **Add user_type column to users table**
   - Add `user_type ENUM('student', 'teacher') DEFAULT 'student'`
   - Update setup_users.php to include the new column
   - Create migration script for existing users

### Phase 2: Backend API Updates
2. **Update register.php**
   - Set default user_type as 'student' during registration
   - Ensure new users get the correct default role

3. **Update update_user.php**
   - Add functionality to update user_type (for admin use)
   - Add validation for role changes

4. **Create role management API**
   - Create endpoint to assign teacher roles
   - Add authentication check for admin operations

### Phase 3: Frontend Updates
5. **Update auth_provider.dart**
   - Handle user_type in authentication state
   - Update user profile to display role information

6. **Update UI components**
   - Display user role in profile
   - Add role-based UI elements if needed

### Phase 4: Testing and Validation
7. **Test the implementation**
   - Test new user registration (should default to student)
   - Test role assignment functionality
   - Test role-based features

## Files to be Modified

### Backend Files:
- `backend/setup_users.php` - Add user_type column to table creation
- `backend/register.php` - Set default user_type during registration
- `backend/update_user.php` - Add role management functionality
- `backend/db.php` - (Check if any database configurations needed)

### New Files:
- `backend/assign_teacher_role.php` - API endpoint for role assignment
- `backend/migrate_user_roles.php` - Migration script for existing users

### Frontend Files:
- `frontend/lib/auth_provider.dart` - Handle user_type in auth state
- `frontend/lib/profile_modal.dart` - Display user role
- `frontend/lib/api_service.dart` - Add role management API calls

## Implementation Steps
1. Database schema update (add user_type column)
2. Update registration to default to 'student'
3. Create role assignment API endpoint
4. Update user profile API to handle roles
5. Update frontend to display and manage roles
6. Test the complete flow

## Success Criteria
- ✅ New users automatically assigned 'student' role during registration
- ✅ Teachers can be assigned through manual/admin process
- ✅ User roles are properly stored and retrieved
- ✅ Frontend displays user roles appropriately
- ✅ Role-based functionality can be implemented on top of this foundation
