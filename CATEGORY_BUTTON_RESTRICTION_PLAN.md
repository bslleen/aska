# Category Button Restriction Plan

## Objective
Make the "Add Category" and "Delete Selected" buttons visible **exclusively** to users with role `admin` or `teacher`.

## Information Gathered

### AuthProvider (frontend/lib/auth_provider.dart)
- Has `isAdmin` property: `bool get isAdmin => _user != null && _user!.userType == 'admin';`
- User type is accessible via: `_user?.userType` (values: 'student', 'teacher', 'admin')

### HomeScreen (frontend/lib/home_screen.dart)
- The buttons are located in the Search Overlay section (lines ~670-690)
- Currently visible to all users
- Need to wrap with role check

### Backend (backend/delete_category.php)
- Admin middleware already exists and restricts backend operations
- Frontend restriction is for UI/UX purposes

## Plan

### Step 1: Modify the Action Buttons Row
Locate the action buttons row in the search overlay (around line 670-690 in home_screen.dart).

**Current Code:**
```dart
// Action buttons row
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    ElevatedButton.icon(
      onPressed: () => _showAddCategoryDialog(),
      // ... button config
    ),
    ElevatedButton.icon(
      onPressed: selectedCategories.isNotEmpty 
          ? _deleteSelectedCategories 
          : null,
      // ... button config
    ),
  ],
),
```

**New Code:**
Wrap the buttons with a conditional check:
```dart
// Action buttons row (only for admin and teacher)
if (context.watch<AuthProvider>().isAdmin || 
    context.watch<AuthProvider>().user?.userType == 'teacher')
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ElevatedButton.icon(
        onPressed: () => _showAddCategoryDialog(),
        // ... button config
      ),
      ElevatedButton.icon(
        onPressed: selectedCategories.isNotEmpty 
            ? _deleteSelectedCategories 
            : null,
        // ... button config
      ),
    ],
  ),
```

### Step 2: Add Informational Text for Non-Admin/Teacher Users
Add a message explaining why buttons are hidden for students:
```dart
// Show message for non-admin/teacher users
if (!context.watch<AuthProvider>().isAdmin && 
    context.watch<AuthProvider>().user?.userType != 'teacher')
  const Padding(
    padding: EdgeInsets.all(16.0),
    child: Text(
      'Category management is restricted to administrators and teachers.',
      style: TextStyle(color: Colors.white54, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  ),
```

## Files to be Modified
- `frontend/lib/home_screen.dart` - Search overlay section

## Follow-up Steps
- Test with admin user - buttons should be visible
- Test with teacher user - buttons should be visible  
- Test with student user - buttons should be hidden, message should appear

