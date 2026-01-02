# Reply Report System Implementation Plan

## Overview
Add a flag button next to all replies that shows a popup with report reasons, and display reported posts/replies in the admin dashboard.

---

## Phase 1: Backend Implementation

### 1.1 Create Database Migration
**File**: `backend/migrate_report_system.php`
- Create `reports` table to store all reports
- Store: report_type (post/reply), target_id, reporter_id, reason, created_at

### 1.2 Create Backend API Endpoints
**File**: `backend/report_reply.php`
- Accept: target_id (reply_id), reporter_id, reason
- Store report in database

**File**: `backend/get_reported_replies.php`
- Fetch all replies with reports
- Include reporter info, reply content, post info

**File**: `backend/get_reported_posts.php`
- Fetch all posts with reports
- Include reporter info, post content, author

**File**: `backend/dismiss_report.php`
- Accept: report_id, report_type
- Mark report as dismissed (keep for records)

**File**: `backend/delete_reported_content.php`
- Accept: target_id, target_type (post/reply)
- Delete the content and associated reports

---

## Phase 2: API Service Updates

### 2.1 Add New Methods to `frontend/lib/api_service.dart`
- `reportReply({required int replyId, required int reporterId, required String reason})`
- `getReportedReplies({required String authToken})`
- `getReportedPosts({required String authToken})`
- `dismissReport({required String authToken, required int reportId, required String reportType})`
- `deleteReportedContent({required String authToken, required int targetId, required String targetType})`

---

## Phase 3: Frontend - Flag Button on Replies

### 3.1 Update `_buildReplyWidget()` in `home_screen.dart`
- Add flag icon button (🚩) in the reply header row
- On tap, show popup menu with options:
  - "Wrong information"
  - "Not related to the question"
  - "Disrespectful"
  - "Other"
- After selection, call `ApiService.reportReply()`
- Show success/error feedback

### 3.2 Add State Variables
- `Set<int> reportedReplies` - Track which replies the current user has reported

---

## Phase 4: Admin Dashboard - Reported Content Tab

### 4.1 Add New Tab in `admin_dashboard.dart`
- Tab 3: "📋 Reported Content"
- Sub-tabs: "Posts" / "Replies"

### 4.2 Implement Reported Posts List
- Fetch via `ApiService.getReportedPosts()`
- Display: Post title, author, reporter, reason, timestamp
- Actions: "Dismiss Report", "Delete Post"

### 4.3 Implement Reported Replies List
- Fetch via `ApiService.getReportedReplies()`
- Display: Reply content, author, reporter, reason, timestamp
- Actions: "Dismiss Report", "Delete Reply"

---

## Phase 5: Testing

### 5.1 Backend Testing
- Test report submission
- Test fetching reported content
- Test dismiss and delete actions

### 5.2 Frontend Testing
- Test flag button visibility and popup
- Test report submission flow
- Test admin dashboard reported content view
- Test dismiss/delete actions

---

## Files to Create/Modify

### New Files:
- `backend/migrate_report_system.php`
- `backend/report_reply.php`
- `backend/get_reported_replies.php`
- `backend/get_reported_posts.php`
- `backend/dismiss_report.php`
- `backend/delete_reported_content.php`

### Modified Files:
- `frontend/lib/api_service.dart` - Add new API methods
- `frontend/lib/home_screen.dart` - Add flag button to replies
- `frontend/lib/admin_dashboard.dart` - Add reported content tab

---

## Status: 📋 PLANNED

