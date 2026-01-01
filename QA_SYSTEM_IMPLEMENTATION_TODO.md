# Q&A System Implementation TODO

## Implementation Status: Started

### Step 1: Execute Database Migration
- [x] 1.1 Run `backend/migrate_qa_system.php` to create database tables
- [x] 1.2 Verify tables were created successfully (category_teachers table, visibility columns)

### Step 2: Create Seed Data
- [x] 2.1 Create `backend/seed_qa_data.php` with test users and categories
- [x] 2.2 Add sample questions and answers
- [x] 2.3 Assign teachers to categories
- **Results**: 8 categories, 3 teachers, 5 students, 5 questions, 10 answers created

### Step 3: Add Category-Teacher Assignment UI (Admin)
- [ ] 3.1 Add 3rd tab to `admin_dashboard.dart` for "Category Assignments"
- [ ] 3.2 Create category-teacher assignment interface
- [ ] 3.3 Integrate with `ApiService.assignTeacherCategory()`

### Step 4: Create Question Detail Screen
- [ ] 4.1 Create `frontend/lib/qa/question_detail_screen.dart`
- [ ] 4.2 Show full question content
- [ ] 4.3 Display all answers (public and private)
- [ ] 4.4 Add answer creation functionality

### Step 5: Add Tap Navigation to Questions
- [ ] 5.1 Update `student_qa_screen.dart` to navigate on question tap
- [ ] 5.2 Update `teacher_qa_dashboard.dart` to navigate on question tap

### Step 6: Create Public Q&A Browse Screen
- [ ] 6.1 Create `frontend/lib/qa/public_qa_browse_screen.dart`
- [ ] 6.2 Show all public Q&A pairs
- [ ] 6.3 Add category filtering
- [ ] 6.4 Integrate with home_screen.dart navigation

### Step 7: Testing & Validation
- [ ] 7.1 Test complete student question workflow
- [ ] 7.2 Test teacher answer workflow with privacy controls
- [ ] 7.3 Test admin category-teacher assignment
- [ ] 7.4 End-to-end flow validation

---

## Color Palette Reference (respect throughout implementation)
```dart
class StudentQAColors {
  static const Color color0 = Color(0xFFC080DD); // Orange/pink accent
  static const Color color1 = Colors.black; // Black background
  static const Color color2 = Color(0xFF38263F); // Dark purple
  static const Color color3 = Color(0xFF52425C); // Medium purple
  static const Color color4 = Color(0xFF7A6284); // Light purple
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
}
```

## Files to Create
- `backend/seed_qa_data.php`
- `frontend/lib/qa/question_detail_screen.dart`
- `frontend/lib/qa/public_qa_browse_screen.dart`

## Files to Modify
- `frontend/lib/admin_dashboard.dart`
- `frontend/lib/qa/student_qa_screen.dart`
- `frontend/lib/qa/teacher_qa_dashboard.dart`
- `frontend/lib/home_screen.dart`

## Documentation
- Update `QA_SYSTEM_ANALYSIS.md` with implementation status
- Create `Q&A_SYSTEM_IMPLEMENTATION_REPORT.md` when complete

