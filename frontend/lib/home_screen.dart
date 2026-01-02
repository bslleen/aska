import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'profile_modal.dart';
import 'admin_dashboard.dart';
import 'qa/student_qa_screen.dart';
import 'qa/teacher_qa_dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> posts = [];
  List<dynamic> categories = [];
  List<dynamic> allPosts = []; // Store all posts for filtering
  bool isLoading = true;
  bool showSearchOverlay = false;
  int? selectedCategoryId; // Single category selection
  List<int> selectedCategories = []; // Multi-select for category deletion

  // Reply system state
  int? expandedPostId;
  Map<int, List<dynamic>> postReplies = {};
  Map<int, bool> repliesLoading = {};
  Map<int, TextEditingController> replyControllers = {};
  Map<int, bool> replying = {};

  // Color palette
  static const Color color0 = Color(0xFFC080DD);
  static const Color color1 = Colors.black;
  static const Color color2 = Color(0xFF38263F);
  static const Color color3 = Color(0xFF52425C);
  static const Color color4 = Color(0xFF7A6284);

  @override
  void initState() {
    super.initState();
    fetchPosts();
    fetchCategories();
  }

  @override
  void dispose() {
    // Dispose all reply controllers
    replyControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // --------------------------
  // Fetch posts
  // --------------------------
  Future<void> fetchPosts() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getPosts();
      setState(() {
        posts = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      setState(() => isLoading = false);
    }
  }

  // --------------------------
  // Fetch categories
  // --------------------------
  Future<void> fetchCategories() async {
    try {
      final data = await ApiService.getCategories();
      setState(() {
        categories = data;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  // --------------------------
  // Load replies for a post
  // --------------------------
  Future<void> _loadReplies(int postId) async {
    setState(() {
      repliesLoading[postId] = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final data = await ApiService.getAnswers(
        postId,
        currentUserId: user?.id,
      );

      setState(() {
        postReplies[postId] = data;
        repliesLoading[postId] = false;
      });
    } catch (e) {
      debugPrint('Error loading replies: $e');
      setState(() {
        repliesLoading[postId] = false;
        postReplies[postId] = [];
      });
    }
  }

  // --------------------------
  // Submit a reply
  // --------------------------
  Future<void> _submitReply(int postId, String content) async {
    if (content.trim().isEmpty) return;

    setState(() {
      replying[postId] = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await ApiService.createAnswer(
        userId: user.id,
        postId: postId,
        content: content.trim(),
      );

      // Clear the input field
      replyControllers[postId]?.clear();

      // Reload replies to show the new one
      await _loadReplies(postId);

      // Update reply count in the post
      setState(() {
        for (var post in posts) {
          if (post['post_id'] == postId) {
            post['reply_count'] = (post['reply_count'] ?? 0) + 1;
            break;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error submitting reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post reply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        replying[postId] = false;
      });
    }
  }

  // --------------------------
  // Toggle post expansion
  // --------------------------
  void _togglePostExpansion(int postId) async {
    if (expandedPostId == postId) {
      // Collapse this post
      setState(() {
        expandedPostId = null;
      });
    } else {
      // Expand this post and load replies
      setState(() {
        expandedPostId = postId;
      });
      await _loadReplies(postId);
    }
  }

  // --------------------------
  // Format timestamp
  // --------------------------
  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  // --------------------------
  // Open Create Post Modal
  // --------------------------
  void openCreatePost() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostModal(onPostCreated: fetchPosts, categories: categories),
    );

    if (result == true) {
      fetchPosts();
    }
  }

  // --------------------------
  // Show Add Category Dialog
  // --------------------------
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        colors: [color0, color1, color2, color3, color4],
        onCategoryCreated: () {
          fetchCategories();
        },
      ),
    );
  }

  // --------------------------
  // Show Delete Category Dialog
  // --------------------------
  void _showDeleteCategoryDialog(dynamic category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: color2,
        title: Text(
          'Delete Category',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${category['name']?.toString() ?? "Unknown"}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSingleCategory(category['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // Filter posts by category
  // --------------------------
  void _filterPostsByCategory(int? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      if (categoryId == null) {
        // Show all posts
        posts = List.from(allPosts);
      } else {
        // Filter posts by category
        posts = allPosts.where((post) {
          return post['category_id'] == categoryId || 
                 post['category']?.toString().toLowerCase() == 
                 categories.firstWhere((c) => c['id'] == categoryId, orElse: () => {'name': ''})['name']?.toString().toLowerCase();
        }).toList();
      }
    });
  }

  // --------------------------
  // Clear category filter
  // --------------------------
  void _clearCategoryFilter() {
    _filterPostsByCategory(null);
  }

  // --------------------------
  // Delete Single Category
  // --------------------------
  Future<void> _deleteSingleCategory(int categoryId) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      print('HomeScreen - _deleteSingleCategory: user = ${user?.username}, id = ${user?.id}');
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final authToken = user.authToken;
      print('HomeScreen - Auth token: ${authToken?.substring(0, 20)}...');
      
      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await ApiService.deleteCategory(
        categoryId: categoryId,
        authToken: authToken!,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Category deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        fetchCategories();
      } else {
        throw Exception(response['error'] ?? 'Failed to delete category');
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------
  // Delete Selected Categories
  // --------------------------
  Future<void> _deleteSelectedCategories() async {
    if (selectedCategories.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: color2,
        title: const Text(
          'Delete Categories',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${selectedCategories.length} selected category(s)? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        int successCount = 0;
        int failCount = 0;

        final authToken = user.authToken;
        if (authToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        for (int categoryId in selectedCategories) {
          try {
            final response = await ApiService.deleteCategory(
              categoryId: categoryId,
              authToken: authToken!,
            );

            if (response['success'] == true) {
              successCount++;
            } else {
              failCount++;
            }
          } catch (e) {
            failCount++;
            debugPrint('Error deleting category $categoryId: $e');
          }
        }

        setState(() {
          selectedCategories.clear();
        });

        fetchCategories();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $successCount category(s)${failCount > 0 ? ', $failCount failed' : ''}'),
            backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      } catch (e) {
        debugPrint('Error deleting categories: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --------------------------
  // Build single post widget
  // --------------------------
  Widget _buildPostWidget(dynamic post) {
    final postId = post['post_id'];
    final isExpanded = expandedPostId == postId;
    final replyCount = post['reply_count'] ?? 0;
    final replies = postReplies[postId] ?? [];
    final isLoadingReplies = repliesLoading[postId] ?? false;
    final isReplying = replying[postId] ?? false;

    // Initialize reply controller if not exists
    if (!replyControllers.containsKey(postId)) {
      replyControllers[postId] = TextEditingController();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpanded ? color2 : color3,
        borderRadius: BorderRadius.circular(16),
        border: isExpanded ? Border.all(color: color0.withOpacity(0.5), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header (always visible)
          GestureDetector(
            onTap: () => _togglePostExpansion(postId),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author and time row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color0,
                      child: Text(
                        (post['author']?.toString() ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['author'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatTime(post['created_at']),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  post['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // Content
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                  maxLines: isExpanded ? null : 3,
                  overflow: isExpanded ? null : TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Category and reply count
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color4,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post['category'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _togglePostExpansion(postId),
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 16,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded content (replies and reply input)
          if (isExpanded) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),

            // Replies section header
            Row(
              children: [
                Icon(Icons.comment, color: color0, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Replies',
                  style: TextStyle(
                    color: color0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Loading indicator
            if (isLoadingReplies)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const CircularProgressIndicator(color: color0),
                ),
              )
            // Replies list
            else if (replies.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'No replies yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                    Text(
                      'Be the first to reply!',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: replies.map((reply) {
                  return _buildReplyWidget(reply);
                }).toList(),
              ),

            const SizedBox(height: 16),

            // Reply input field
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color3,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyControllers[postId],
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: color2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  isReplying
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2, color: color0),
                          ),
                        )
                      : IconButton(
                          onPressed: () {
                            final content = replyControllers[postId]?.text;
                            if (content != null && content.trim().isNotEmpty) {
                              _submitReply(postId, content);
                            }
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color0,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------
  // Build Category Card Widget (Wattpad-style)
  // --------------------------
  Widget _buildCategoryCard(dynamic category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedCategories.remove(category['id']);
          } else {
            selectedCategories.add(category['id']);
          }
        });
      },
      onLongPress: () => _showDeleteCategoryDialog(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? color0 : color4,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? color0 : Colors.black).withOpacity(isSelected ? 0.5 : 0.3),
              spreadRadius: isSelected ? 4 : 2,
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: color0,
                  ),
                ),
              Text(
                category['name']?.toString() ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------
  // Build single reply widget
  // --------------------------
  Widget _buildReplyWidget(dynamic reply) {
    final replyId = reply['id'];
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color2.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply header
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color4,
                child: Text(
                  (reply['author']?.toString() ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply['author'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _formatTime(reply['created_at']),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (reply['is_accepted'] == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✓ Accepted',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              // Flag button for reporting
              if (currentUser != null && currentUser.id != reply['user_id'])
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.flag_outlined,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onSelected: (value) {
                    _showReportDialog(replyId, value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'wrong_info',
                      child: Text('Wrong information'),
                    ),
                    const PopupMenuItem(
                      value: 'not_related',
                      child: Text('Not related to the question'),
                    ),
                    const PopupMenuItem(
                      value: 'disrespectful',
                      child: Text('Disrespectful'),
                    ),
                    const PopupMenuItem(
                      value: 'other',
                      child: Text('Other'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Reply content
          Text(
            reply['content'] ?? '',
            style: const TextStyle(color: Color(0xE6FFFFFF)), // white90 equivalent
          ),
        ],
      ),
    );
  }

  // --------------------------
  // Show Report Dialog
  // --------------------------
  void _showReportDialog(int targetId, String reason) {
    final reasonDisplay = {
      'wrong_info': 'Wrong information',
      'not_related': 'Not related to the question',
      'disrespectful': 'Disrespectful',
      'other': 'Other',
    }[reason] ?? reason;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: color2,
        title: const Text(
          'Report Reply',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to report this reply for "$reasonDisplay"?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (reason == 'other')
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Additional details (optional)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: color3,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
                onChanged: (value) {
                  // Store additional details
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitReport(targetId, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // Submit Report
  // --------------------------
  Future<void> _submitReport(int replyId, String reason) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null || user.authToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await ApiService.reportReply(
        authToken: user.authToken!,
        replyId: replyId,
        reason: reason,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply reported successfully. Thank you for keeping the community safe!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to report reply');
      }
    } catch (e) {
      debugPrint('Error reporting reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to report reply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Top Bar: username + admin dashboard + search
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color1,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const ProfileModal(),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                context.watch<AuthProvider>().user?.username ?? 'User',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              if (context.watch<AuthProvider>().isAdmin) ...[
                                const SizedBox(width: 8),
                                const Text('👑', style: TextStyle(fontSize: 16)),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Q&A Navigation Buttons
                            if (context.watch<AuthProvider>().user?.userType == 'teacher') ...[
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TeacherQADashboard(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.school, color: Colors.green),
                                tooltip: 'Teacher Q&A Dashboard',
                              ),
                            ],
                            if (context.watch<AuthProvider>().user?.userType == 'student') ...[
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StudentQAScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.question_answer, color: Colors.blue),
                                tooltip: 'My Questions & Answers',
                              ),
                            ],
                            if (context.watch<AuthProvider>().isAdmin)
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminDashboard(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                                tooltip: 'Admin Dashboard',
                              ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  showSearchOverlay = true;
                                });
                              },
                              icon: const Icon(Icons.search, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Write Post Section
                  GestureDetector(
                    onTap: openCreatePost,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "What's on your mind?",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Posts feed
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: color0))
                        : RefreshIndicator(
                            onRefresh: fetchPosts,
                            color: color0,
                            child: posts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.post_add, color: Colors.white24, size: 60),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No posts yet',
                                          style: TextStyle(color: Colors.white54, fontSize: 18),
                                        ),
                                        const Text(
                                          'Be the first to create a post!',
                                          style: TextStyle(color: Colors.white38),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: posts.length,
                                    itemBuilder: (context, index) {
                                      final post = posts[index];
                                      return _buildPostWidget(post);
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // --------------------------
          // Search Overlay (Full Screen)
          // --------------------------
          if (showSearchOverlay)
            Positioned.fill(
              child: Container(
                color: color1,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Header with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Search Categories',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => showSearchOverlay = false),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color2,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Action buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showAddCategoryDialog(),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Add Category', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: selectedCategories.isNotEmpty 
                                  ? _deleteSelectedCategories 
                                  : null,
                              icon: const Icon(Icons.delete, color: Colors.white),
                              label: const Text('Delete Selected', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedCategories.isNotEmpty 
                                    ? Colors.red 
                                    : Colors.grey,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Category cards grid
                        Expanded(
                          child: categories.isEmpty
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final cat = categories[index];
                                    final isSelected = selectedCategories.contains(cat['id']);
                                    return _buildCategoryCard(cat, isSelected);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------
// CREATE POST MODAL
// ----------------------
class CreatePostModal extends StatefulWidget {
  final VoidCallback onPostCreated;
  final List<dynamic> categories;
  const CreatePostModal({Key? key, required this.onPostCreated, required this.categories}) : super(key: key);

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  dynamic selectedCategory;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      selectedCategory = widget.categories.first;
    }
  }

  void submitPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await ApiService.createPost(
        userId: user.id,
        categoryId: selectedCategory['id'],
        title: _titleController.text,
        content: _contentController.text,
      );

      widget.onPostCreated();
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color2 = const Color(0xFF38263F);
    final Color color4 = const Color(0xFF7A6284);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF38263F),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF52425C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Content',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF52425C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC080DD),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------
// ADD CATEGORY DIALOG
// ----------------------
class AddCategoryDialog extends StatefulWidget {
  final List<Color> colors;
  final VoidCallback onCategoryCreated;
  const AddCategoryDialog({Key? key, required this.colors, required this.onCategoryCreated}) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _nameController = TextEditingController();
  bool isSubmitting = false;

  void submitCategory() async {
    if (_nameController.text.isEmpty) return;

    setState(() => isSubmitting = true);

    try {
      await ApiService.createCategory(
        name: _nameController.text,
      );

      widget.onCategoryCreated();
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create category: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.colors[2],
      title: const Text('Add New Category', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Category Name',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: widget.colors[3],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : submitCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.colors[0],
          ),
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

