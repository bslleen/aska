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
  int _selectedTab = 0;

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
      return const Scaffold(
        body: Center(
          child: Text('Access denied. Admin privileges required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard 👑'),
        backgroundColor: Colors.deepPurple,
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
                      backgroundColor: _selectedTab == 0 ? Colors.deepPurple : Colors.grey[300],
                      foregroundColor: _selectedTab == 0 ? Colors.white : Colors.black,
                    ),
                    child: Text('👥 Users (${_users.length})'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                      _loadAdminData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 1 ? Colors.deepPurple : Colors.grey[300],
                      foregroundColor: _selectedTab == 1 ? Colors.white : Colors.black,
                    ),
                    child: Text('📝 Posts (${_posts.length})'),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAdminData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _selectedTab == 0
                        ? _buildUsersList()
                        : _buildPostsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final roleIcon = user['user_type'] == 'admin' ? '👑' : 
                        user['user_type'] == 'teacher' ? '👨‍🏫' : '👨‍🎓';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(roleIcon),
            ),
            title: Text('${user['username']} ($roleIcon ${user['user_type']})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user['email']}'),
                Text('Posts: ${user['post_count']}, Answers: ${user['answer_count']}'),
                Text('Joined: ${user['created_at']}'),
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
            ),
            onLongPress: user['user_type'] != 'admin' ? () => _deleteUser(user['id']) : null,
          ),
        );
      },
    );
  }

  Widget _buildPostsList() {
    if (_posts.isEmpty) {
      return const Center(child: Text('No posts found'));
    }

    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(post['title'] ?? 'No title'),
            subtitle: Text('By: ${post['author'] ?? 'Unknown'} | Category: ${post['category'] ?? 'Unknown'}'),
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

