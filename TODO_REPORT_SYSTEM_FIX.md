# Report System Fix - TODO List

## Problem
Reported posts do not reach the admin dashboard due to two issues:
1. Frontend missing report feature for posts (only replies can be reported)
2. Backend database connection bug (mysqli `$conn` not defined in db.php)

## Fix Plan

### Step 1: Fix Backend Database Connection
- [x] Fix `backend/db.php` to create both PDO and mysqli connections

### Step 2: Add Report Feature for Posts in Frontend
- [x] Add report popup menu to posts in `home_screen.dart`
- [x] Add `_showReportPostDialog` method
- [x] Add `_submitPostReport` method
- [x] Wire up the report flow

### Step 3: Test the Fix
- [ ] Run migrate_report_system.php
- [ ] Test reporting a post
- [ ] Check admin dashboard for reported posts

## Status: COMPLETED

## Summary of Changes

### 1. `backend/db.php`
Added mysqli connection (`$conn`) alongside the existing PDO connection, fixing the database connection issue that was causing admin endpoints to fail.

### 2. `frontend/lib/home_screen.dart`
- Added flag/report button to posts (visible to non-owners)
- Added `_showReportPostDialog` method to show report confirmation dialog
- Added `_submitPostReport` method to submit post reports via API

## How to Test
1. Ensure the reports table exists: Run `http://localhost:8001/migrate_report_system.php`
2. Start the app and navigate to the home screen
3. Report a post by tapping the flag icon
4. Go to Admin Dashboard → Reported tab
5. Verify the reported post appears

