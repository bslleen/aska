# Teacher-Student Q&A Implementation Plan

## Current System Analysis
✅ **Already Working**:
- User authentication with roles (student/teacher/admin)
- Categories system (subjects)
- Posts and answers system
- User management
- Basic voting system

## Missing Components for Q&A Workflow

### 1. 🔗 Category-Teacher Assignment
**Need**: Link teachers to specific categories/subjects
**Implementation**:
```sql
ALTER TABLE categories ADD COLUMN assigned_teacher_id INT;
-- or create junction table: category_teachers (category_id, teacher_id)
```

### 2. 📧 Teacher Notifications
**Need**: Notify teachers when students ask questions in their subjects
**Implementation**:
- Add notification system
- Real-time updates for teachers
- Email notifications (optional)

### 3. 🔒 Privacy Control for Answers
**Need**: Teachers can mark answers as public or private
**Current**: All answers are public
**Implementation**:
```sql
ALTER TABLE answers ADD COLUMN visibility ENUM('public', 'private') DEFAULT 'public';
ALTER TABLE answers ADD COLUMN target_student_id INT; -- for private answers
```

### 4. 👀 Student View Filtering
**Need**: Students only see public answers, private answers only to the asking student
**Implementation**:
- Update `get_answers.php` to filter based on user role and privacy
- Add visibility checks

### 5. 📊 Teacher Dashboard Enhancements
**Need**: Teachers see questions in their assigned subjects
**Implementation**:
- Update teacher dashboard to show category-filtered posts
- Add "my subjects" section

## Implementation Steps

### Phase 1: Database Schema Updates
1. **Category-Teacher Assignment**
   - Create `category_teachers` junction table
   - Populate existing teacher-category relationships

2. **Answer Privacy**
   - Add `visibility` and `target_student_id` columns to answers
   - Update existing answers to default 'public'

### Phase 2: Backend API Updates
1. **Enhanced Category APIs**
   - `get_categories.php` - include assigned teacher info
   - `assign_teacher_category.php` - admin assigns teacher to category

2. **Privacy-Controlled Answers**
   - Update `create_answer.php` to accept privacy setting
   - Update `get_answers.php` to filter by privacy and user role

3. **Teacher-Specific Queries**
   - `get_teacher_questions.php` - questions for teacher's subjects
   - `get_student_answers.php` - student's questions and answers

### Phase 3: Frontend Updates
1. **Student Interface**
   - Subject selection screen
   - Question creation with category selection
   - Answer viewing (public only, with private answers from own questions)

2. **Teacher Interface**
   - Dashboard showing questions from assigned subjects
   - Answer creation with privacy controls
   - Subject management

3. **Admin Interface**
   - Category-teacher assignment interface
   - Overall Q&A analytics

### Phase 4: Testing & Polish
1. **Role-Based Testing**
   - Test student experience
   - Test teacher experience
   - Test admin functionality

2. **Privacy Testing**
   - Verify private answers only visible to target student
   - Verify public answers visible to all

## Example Workflow Implementation

### Student Asks Question
1. Student logs in → selects subject → creates post
2. System assigns post to category → notifies assigned teachers
3. Teachers see new question in their dashboard

### Teacher Answers
1. Teacher views question → creates answer
2. Teacher selects privacy: "Public" or "Private"
3. If private: only asking student sees answer
4. If public: all students see answer

### Student Views Answer
1. Student sees their question in "My Questions"
2. Student sees all public answers to questions in their subjects
3. Student sees private answers only to their own questions

## Files to Modify/Create

### Backend Files to Modify
- `backend/get_categories.php` - include teacher assignments
- `backend/create_answer.php` - add privacy controls
- `backend/get_answers.php` - add privacy filtering
- `backend/get_posts.php` - filter by teacher assignments

### Backend Files to Create
- `backend/assign_teacher_category.php` - admin assigns teacher
- `backend/get_teacher_questions.php` - teacher's assigned questions
- `backend/get_student_answers.php` - student's Q&A history

### Frontend Files to Create/Modify
- `frontend/lib/qa/` directory for Q&A specific screens
- Update `teacher_dashboard.dart` for subject-specific questions
- Update `home_screen.dart` for category selection

## Security Considerations
- Verify teacher has permission to answer questions in their assigned categories
- Ensure privacy controls are enforced on backend (not just frontend)
- Validate that private answers only reach intended students

## Success Metrics
- Students can successfully ask questions in specific subjects
- Teachers receive and can answer questions in their subjects
- Privacy controls work correctly
- All user roles function as expected
- System scales to multiple subjects and teachers
