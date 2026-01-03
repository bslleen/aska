# Teacher QA Dashboard Fix - TODO

## Objective
Fix the teacher dashboard not receiving subject-related questions and create test questions for teacher selena (pwd: selena1234)

## Steps

### Step 1: Create setup_teacher_selena.php
- [x] Create teacher "selena" with password "selena1234"
- [x] Assign selena to multiple categories
- [x] Create test questions in those categories

### Step 2: Improve get_teacher_questions.php
- [ ] Add better error handling and logging
- [ ] Add debug response for troubleshooting

### Step 3: Run migrations and setup
- [ ] Run migrate_qa_system.php to ensure tables exist
- [ ] Run seed_qa_data.php for sample data
- [ ] Run setup_teacher_selena.php for selena

### Step 4: Test
- [ ] Verify selena can login
- [ ] Verify selena sees questions in her dashboard

## Current Issues Identified
1. Teacher "selena" doesn't exist in the database
2. Teacher-category assignments may be missing
3. Questions may not be in the right categories

## Test Account
- Username: selena
- Password: selena1234

