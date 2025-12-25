
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart'; // Make sure this is the correct path
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
  bool isLoading = true;
  bool showSearchOverlay = false;
  Set<int> selectedCategories = {};

  // Color palette
  final Color color0 = const Color(0xFFC080DD);
  final Color color1 = Colors.black; // fully black background
  final Color color2 = const Color(0xFF38263F);
  final Color color3 = const Color(0xFF52425C);
  final Color color4 = const Color(0xFF7A6284);

  @override
  void initState() {
    super.initState();
    fetchPosts();
    fetchCategories();
  }

  // --------------------------
  // Fetch posts
  // --------------------------
  Future<void> fetchPosts() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getPosts(); // call static method directly
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
      final data = await ApiService.getCategories(); // call static method
      setState(() {
        categories = data;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
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
          fetchCategories(); // Refresh categories list
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
        fetchCategories(); // Refresh categories list
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

        fetchCategories(); // Refresh categories list

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
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: fetchPosts,
                            child: ListView.builder(
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                final post = posts[index];
                                final category = post['category'] as String?;
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color3,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post['title'],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        post['content'],
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Category: ${category ?? "Unknown"}',
                                        style: const TextStyle(
                                            color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // --------------------------
          // Search Overlay
          // --------------------------
          if (showSearchOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showSearchOverlay = false),
                child: Container(
                  color: color1.withOpacity(0.95),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: categories.isEmpty
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: categories
                                      .map(
                                        (cat) => FilterChip(
                                          backgroundColor: selectedCategories.contains(cat['id']) 
                                              ? color0 
                                              : color4,
                                          selected: selectedCategories.contains(cat['id']),
                                          label: Text(
                                            cat['name']?.toString() ?? 'Unknown',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          onSelected: (bool selected) {
                                            setState(() {
                                              if (selected) {
                                                selectedCategories.add(cat['id']);
                                              } else {
                                                selectedCategories.remove(cat['id']);
                                              }
                                            });
                                          },
                                          deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
                                          onDeleted: () => _showDeleteCategoryDialog(cat),
                                          selectedColor: color0,
                                          checkmarkColor: Colors.white,
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showAddCategoryDialog(),
                                      icon: const Icon(Icons.add, color: Colors.white),
                                      label: const Text('Add Category', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color0,
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
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
