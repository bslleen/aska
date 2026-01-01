# EDIT/DELETE POSTS & REPLIES - IMPLEMENTATION PLAN

## Task Summary
Implement edit/delete functionality for posts and replies using long-press gestures:
- Long-press on own post → Show edit/delete options
- Long-press on own reply → Show edit/delete options

---

## Current State Analysis

### Backend Files
| File | Status | Issue |
|------|--------|-------|
| `get_posts.php` | Needs Update | Returns `user_id` as `author` (username), not actual user ID |
| `get_answers.php` | Needs Update | Returns `author` (username), not actual user ID |
| `create_post.php` | OK | Works correctly |
| `create_answer.php` | OK | Works correctly |
| `delete_post.php` | Exists | Only for admins, requires auth token |
| `update_post.php` | **MISSING** | Need to create |
| `delete_answer.php` | **MISSING** | Need to create |
| `update_answer.php` | **MISSING** | Need to create |

### Frontend Files
| File | Status | Issue |
|------|--------|-------|
| `home_screen.dart` | Needs Update | No ownership check, no long-press, no edit/delete |
| `api_service.dart` | Needs Update | No update/delete answer endpoints |

---

## Implementation Plan

### PHASE 1: Backend Updates

#### 1.1 Modify `get_posts.php`
Add `p.user_id` to the SELECT query:
```php
SELECT 
    p.id AS post_id, 
    p.user_id,  // ADD THIS
    p.title, 
    p.content, 
    ...
```

#### 1.2 Modify `get_answers.php`
Add `a.user_id` to the SELECT query:
```php
SELECT 
    a.id AS answer_id, 
    a.user_id,  // ADD THIS
    a.content, 
    ...
```

#### 1.3 Create `backend/update_post.php`
- Endpoint to update post title and content
- Verify ownership via auth token
- Only post owner can update

#### 1.4 Create `backend/delete_post_user.php`
- Endpoint to delete own post
- Verify ownership via auth token
- Cascade delete associated answers and votes

#### 1.5 Create `backend/update_answer.php`
- Endpoint to update answer content
- Verify ownership via auth token
- Only answer owner can update

#### 1.6 Create `backend/delete_answer.php`
- Endpoint to delete own answer
- Verify ownership via auth token
- Cascade delete associated votes

---

### PHASE 2: Frontend Updates

#### 2.1 Update `api_service.dart`
Add new API methods:
- `updatePost({required String authToken, required int postId, String? title, String? content})`
- `deletePostUser({required String authToken, required int postId})`
- `updateAnswer({required String authToken, required int answerId, required String content})`
- `deleteAnswer({required String authToken, required int answerId})`

#### 2.2 Update `home_screen.dart`

**State Management:**
```dart
// Track which post/reply is being edited
int? editingPostId;
int? editingReplyId;
TextEditingController? editTitleController;
TextEditingController? editContentController;
```

**UI Changes:**

1. **Post Widget (`_buildPostWidget`):**
   - Wrap with `GestureDetector` for long-press
   - Add owner check: `post['user_id'] == currentUser?.id`
   - Show context menu on long-press if owner

2. **Reply Widget (`_buildReplyWidget`):**
   - Wrap with `GestureDetector` for long-press
   - Add owner check: `reply['user_id'] == currentUser?.id`
   - Show context menu on long-press if owner

3. **Context Menu Implementation:**
   - Use `showModalBottomSheet` or `PopupMenuButton`
   - Options: "Edit", "Delete"
   - Edit → Opens edit modal
   - Delete → Shows confirmation dialog → calls API

4. **Edit Modals:**
   - Post Edit Modal: Title + Content fields, Save button
   - Reply Edit Modal: Content field, Save button

---

## Detailed Code Changes

### Backend File: `backend/update_post.php`
```php
// Validate auth token
// Verify user owns the post
// Update title and/or content
// Return success/error
```

### Backend File: `backend/delete_post_user.php`
```php
// Validate auth token
// Verify user owns the post
// Delete post + cascade delete answers + votes
// Return success/error
```

### Backend File: `backend/update_answer.php`
```php
// Validate auth token
// Verify user owns the answer
// Update content
// Return success/error
```

### Backend File: `backend/delete_answer.php`
```php
// Validate auth token
// Verify user owns the answer
// Delete answer + cascade delete votes
// Return success/error
```

---

## User Experience Flow

### Long-Press on Own Post:
1. User long-presses on a post they created
2. Bottom sheet appears with options: "Edit Post" | "Delete Post"
3. User taps "Edit Post" → Edit Modal opens with current content
4. User modifies and taps "Save" → API call → Post updated
5. OR User taps "Delete Post" → Confirmation dialog → Delete → API call → Post removed

### Long-Press on Own Reply:
1. User long-presses on a reply they created
2. Bottom sheet appears with options: "Edit Reply" | "Delete Reply"
3. User taps "Edit Reply" → Edit Modal opens with current content
4. User modifies and taps "Save" → API call → Reply updated
5. OR User taps "Delete Reply" → Confirmation dialog → Delete → API call → Reply removed

### Long-Press on Others' Content:
1. User long-presses on someone else's post/reply
2. No options appear (or show "Report" option in future)

---

## Files to Modify/Create

### New Files:
- `backend/update_post.php`
- `backend/delete_post_user.php`
- `backend/update_answer.php`
- `backend/delete_answer.php`

### Modified Files:
- `backend/get_posts.php` - Add user_id field
- `backend/get_answers.php` - Add user_id field
- `frontend/lib/api_service.dart` - Add 4 new API methods
- `frontend/lib/home_screen.dart` - Add long-press, ownership check, edit/delete UI

---

## Testing Plan

1. **Ownership Check Test:**
   - Create post as User A
   - Verify User A sees edit/delete options on long-press
   - Verify User B does NOT see edit/delete options

2. **Edit Post Test:**
   - Long-press → Edit → Modify → Save
   - Verify post updates in UI
   - Verify data persists on refresh

3. **Delete Post Test:**
   - Long-press → Delete → Confirm
   - Verify post removed from UI
   - Verify associated replies also removed

4. **Edit Reply Test:**
   - Long-press on reply → Edit → Modify → Save
   - Verify reply updates in UI

5. **Delete Reply Test:**
   - Long-press on reply → Delete → Confirm
   - Verify reply removed from UI
   - Verify reply count on post decrements

---

## Timeline

- Phase 1 (Backend): 30 minutes
- Phase 2 (Frontend): 45 minutes
- Testing & Polish: 15 minutes
- **Total: ~90 minutes**

---

## Dependencies

- Auth token validation (existing in `token_utils.php`)
- Database connection (existing in `db.php`)
- API service integration (existing structure)

