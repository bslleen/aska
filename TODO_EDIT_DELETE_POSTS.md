# Edit/Delete Own Posts - Implementation TODO

## Phase 1: Backend Updates
- [x] 1.1 Modify `backend/get_posts.php` - Add `p.user_id` field
- [x] 1.2 Modify `backend/get_answers.php` - Add `a.user_id` field
- [x] 1.3 Create `backend/update_post.php` - Update post with ownership check
- [x] 1.4 Create `backend/delete_post_user.php` - Delete own post with ownership check
- [x] 1.5 Create `backend/update_answer.php` - Update reply with ownership check
- [x] 1.6 Create `backend/delete_answer.php` - Delete own reply with ownership check

## Phase 2: Frontend Updates
- [x] 2.1 Create `frontend/lib/edit_modals.dart` - (Included in home_screen.dart as inline modals)
- [x] 2.2 Update `frontend/lib/api_service.dart` - Add 4 new API methods
- [x] 2.3 Update `frontend/lib/home_screen.dart`:
  - [x] Add 3-dot menu on post widget
  - [x] Add ownership check
  - [x] Add edit functionality
  - [x] Add delete functionality

## Testing
- [ ] Test post ownership check
- [ ] Test edit post functionality
- [ ] Test delete post functionality
- [ ] Test reply ownership check (future)


