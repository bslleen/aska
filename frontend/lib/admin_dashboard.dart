import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _users = [];
  List<dynamic> _posts = [];
  List<dynamic> _reportedPosts = [];
  List<dynamic> _reportedReplies = [];
  int _selectedTab = 0; // 0: Users, 1: Posts, 2: Reported Content
  int _reportSubTab = 0; // 0: Posts, 1: Replies

  // Color palette - matching the app's theme
  static const Color color0 = Color(0xFFC080DD); // Pink/lilac (main accent)
  static const Color color1 = Colors.black; // Black (background)
  static const Color color2 = Color(0xFF38263F); // Dark purple
  static const Color color3 = Color(0xFF52425C); // Medium purple
  static const Color color4 = Color(0xFF7A6284); // Light purple

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied. Admin privileges required.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_selectedTab == 0) {
        await _loadUsers();
      } else {
        await _loadPosts();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getAllUsers(authToken: authProvider.user!.authToken!);
    
    setState(() {
      _users = response['data'] ?? [];
    });
  }

  Future<void> _loadPosts() async {
    final response = await ApiService.getPosts();
    setState(() {
      _posts = response;
    });
  }

  // --------------------------
  // Load reported posts
  // --------------------------
  Future<void> _loadReportedPosts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getReportedPosts(
      authToken: authProvider.user!.authToken!,
    );
    
    setState(() {
      _reportedPosts = response['data'] ?? [];
    });
  }

  // --------------------------
  // Load reported replies
  // --------------------------
  Future<void> _loadReportedReplies() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getReportedReplies(
      authToken: authProvider.user!.authToken!,
    );
    
    setState(() {
      _reportedReplies = response['data'] ?? [];
    });
  }

  // --------------------------
  // Load all reported content
  // --------------------------
  Future<void> _loadReportedContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadReportedPosts();
      await _loadReportedReplies();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --------------------------
  // Dismiss a report
  // --------------------------
  Future<void> _dismissReport(int reportId, String reportType) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: color2,
        title: const Text('Dismiss Report', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to dismiss this report? The content will remain visible.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: color0),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.dismissReport(
          authToken: authProvider.user!.authToken!,
          reportId: reportId,
          reportType: reportType,
        );
        
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Report dismissed successfully', style: TextStyle(color: Colors.white)), backgroundColor: color2),
          );
          await _loadReportedContent();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss report: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --------------------------
  // Delete reported content
  // --------------------------
  Future<void> _deleteReportedContent(int targetId, String targetType, String contentTitle) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reported Content'),
        content: Text('Are you sure you want to delete this $targetType?\n\n"$contentTitle"\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteReportedContent(
          authToken: authProvider.user!.authToken!,
          targetId: targetId,
          targetType: targetType,
        );
        
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${targetType[0].toUpperCase()}${targetType.substring(1)} deleted successfully')),
          );
          await _loadReportedContent();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete content: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(int userId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteUser(
          authToken: authProvider.user!.authToken!,
          userId: userId,
        );
        
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'User deleted successfully')),
          );
          await _loadUsers(); // Refresh the list
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }

  Future<void> _deletePost(int postId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deletePost(
          authToken: authProvider.user!.authToken!,
          postId: postId,
        );
        
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Post deleted successfully')),
          );
          await _loadPosts(); // Refresh the list
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }

  Future<void> _changeUserRole(int userId, String newRole) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final response = await ApiService.assignUserRole(
        authToken: authProvider.user!.authToken!,
        userId: userId,
        userType: newRole,
      );
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Role updated successfully')),
        );
        await _loadUsers(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isAdmin) {
      return Scaffold(
        backgroundColor: color1,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'Access denied',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Admin privileges required.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: color1,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: color2,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                      _loadAdminData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 0 ? color0 : color3,
                      foregroundColor: _selectedTab == 0 ? Colors.white : Colors.white,
                    ),
                    child: Text('👥 Users (${_users.length})'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                      _loadAdminData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 1 ? color0 : color3,
                      foregroundColor: _selectedTab == 1 ? Colors.white : Colors.white,
                    ),
                    child: Text('📝 Posts (${_posts.length})'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 2;
                      });
                      _loadReportedContent();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 2 ? color0 : color3,
                      foregroundColor: _selectedTab == 2 ? Colors.white : Colors.white,
                    ),
                    child: Text('🚩 Reported (${_reportedPosts.length + _reportedReplies.length})'),
                  ),
                ),
              ],
            ),
          ),
          
          // Report sub-tab (only show when reported content tab is selected)
          if (_selectedTab == 2)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _reportSubTab = 0;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _reportSubTab == 0 ? color0 : color4,
                        foregroundColor: _reportSubTab == 0 ? Colors.white : Colors.white,
                      ),
                      child: Text('📄 Posts (${_reportedPosts.length})'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _reportSubTab = 1;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _reportSubTab == 1 ? color0 : color4,
                        foregroundColor: _reportSubTab == 1 ? Colors.white : Colors.white,
                      ),
                      child: Text('💬 Replies (${_reportedReplies.length})'),
                    ),
                  ),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: color0,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAdminData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color0,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _selectedTab == 0
                        ? _buildUsersList()
                        : _selectedTab == 1
                            ? _buildPostsList()
                            : _buildReportedContentList(),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // Build Reported Content List
  // --------------------------
  Widget _buildReportedContentList() {
    if (_reportSubTab == 0) {
      // Reported Posts
      if (_reportedPosts.isEmpty) {
        return Center(
          child: Text(
            'No reported posts',
            style: TextStyle(color: Colors.white54),
          ),
        );
      }
      return ListView.builder(
        itemCount: _reportedPosts.length,
        itemBuilder: (context, index) {
          final item = _reportedPosts[index];
          final post = item['post'];
          final reporter = item['reporter'];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: color2,
            child: ExpansionTile(
              title: Text(
                post['title'] ?? 'No title',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                'By: ${post['author']['username'] ?? 'Unknown'} | Reported by: ${reporter['username'] ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white70),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post Content: ${post['content'] ?? 'No content'}',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reason: ${item['reason_display'] ?? item['reason']}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reported at: ${item['reported_at']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _dismissReport(item['report_id'], 'post'),
                            icon: const Icon(Icons.check),
                            label: const Text('Dismiss'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color4,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _deleteReportedContent(
                              post['id'],
                              'post',
                              post['title'] ?? 'Untitled Post',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Post'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Reported Replies
      if (_reportedReplies.isEmpty) {
        return Center(
          child: Text(
            'No reported replies',
            style: TextStyle(color: Colors.white54),
          ),
        );
      }
      return ListView.builder(
        itemCount: _reportedReplies.length,
        itemBuilder: (context, index) {
          final item = _reportedReplies[index];
          final reply = item['reply'];
          final reporter = item['reporter'];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: color2,
            child: ExpansionTile(
              title: const Text(
                'Reported Reply',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                'By: ${reply['author']['username'] ?? 'Unknown'} | Reported by: ${reporter['username'] ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white70),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reply: ${reply['content'] ?? 'No content'}',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reason: ${item['reason_display'] ?? item['reason']}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'On post: ${item['post']['title'] ?? 'Unknown'}',
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reported at: ${item['reported_at']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _dismissReport(item['report_id'], 'reply'),
                            icon: const Icon(Icons.check),
                            label: const Text('Dismiss'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color4,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _deleteReportedContent(
                              reply['id'],
                              'reply',
                              reply['content']?.substring(0, 30) ?? 'Untitled Reply',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Reply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final roleIcon = user['user_type'] == 'admin' ? '👑' : 
                        user['user_type'] == 'teacher' ? '👨‍🏫' : '👨‍🎓';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: color2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color0,
              child: Text(roleIcon, style: const TextStyle(fontSize: 16)),
            ),
            title: Text(
              '${user['username']} ($roleIcon ${user['user_type']})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user['email']}', style: const TextStyle(color: Colors.white70)),
                Text('Posts: ${user['post_count']}, Answers: ${user['answer_count']}', style: const TextStyle(color: Colors.white70)),
                Text('Joined: ${user['created_at']}', style: const TextStyle(color: Colors.white54)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value != user['user_type']) {
                  _changeUserRole(user['id'], value);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'student',
                  child: Text('👨‍🎓 Make Student'),
                ),
                const PopupMenuItem(
                  value: 'teacher',
                  child: Text('👨‍🏫 Make Teacher'),
                ),
                if (user['user_type'] != 'admin')
                  const PopupMenuItem(
                    value: 'admin',
                    child: Text('👑 Make Admin'),
                  ),
              ],
              color: color2,
            ),
            onLongPress: user['user_type'] != 'admin' ? () => _deleteUser(user['id']) : null,
          ),
        );
      },
    );
  }

  Widget _buildPostsList() {
    if (_posts.isEmpty) {
      return Center(
        child: Text(
          'No posts found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: color2,
          child: ListTile(
            title: Text(
              post['title'] ?? 'No title',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'By: ${post['author'] ?? 'Unknown'} | Category: ${post['category'] ?? 'Unknown'}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePost(post['post_id']),
            ),
            onLongPress: () => _deletePost(post['post_id']),
          ),
        );
      },
    );
  }
}

