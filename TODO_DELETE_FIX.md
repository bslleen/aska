# TODO: Fix Type Mismatch Error When Deleting Posts

## Problem
Error: `type 'String' is not a subtype of type 'int'`
- MySQL returns IDs as strings in JSON response
- ApiService methods expect `int` parameters
- Occurs when deleting: normal posts, reported posts, and reported replies

## Fix Locations

### 1. admin_dashboard.dart - `_buildPostsList`
- **Issue**: `post['post_id']` is String, passed to `_deletePost(post['post_id'])`
- **Fix**: Convert to int: `_deletePost(int.parse(post['post_id'].toString()))`
- **Status**: ✅ COMPLETED

### 2. admin_dashboard.dart - `_buildReportedContentList` (Reported Posts)
- **Issue**: `post['id']` is String, passed to `_deleteReportedContent(post['id'], ...)`
- **Fix**: Convert to int: `_deleteReportedContent(int.parse(post['id'].toString()), ...)`
- **Status**: ✅ COMPLETED

### 3. admin_dashboard.dart - `_buildReportedContentList` (Reported Replies)
- **Issue**: `reply['id']` is String, passed to `_deleteReportedContent(reply['id'], ...)`
- **Fix**: Convert to int: `_deleteReportedContent(int.parse(reply['id'].toString()), ...)`
- **Status**: ✅ COMPLETED

## Summary
All fixes have been applied. The type mismatch error should now be resolved for:
- Normal posts deletion (Admin Dashboard → Posts tab)
- Reported posts deletion (Admin Dashboard → Reported tab → Posts subtab)
- Reported replies deletion (Admin Dashboard → Reported tab → Replies subtab)

