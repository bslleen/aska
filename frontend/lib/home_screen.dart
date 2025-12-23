
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart'; // Make sure this is the correct path
import 'auth_provider.dart';
import 'profile_modal.dart';

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

  // Color palette
  final Color color0 = const Color(0xFFC080D);
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
      builder: (_) => CreatePostModal(onPostCreated: fetchPosts),
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
                  // Top Bar: username + search
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color0,
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
                          child: Text(
                            context.watch<AuthProvider>().user?.username ?? 'User',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
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
                                        'Category: ${post['category'] ?? "Unknown"}',
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
                                        (cat) => Chip(
                                          backgroundColor: color4,
                                          label: Text(
                                            cat['name'],
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddCategoryDialog(),
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text('Add Category', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color0,
                                  ),
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
  const CreatePostModal({Key? key, required this.onPostCreated}) : super(key: key);

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool isSubmitting = false;

  void submitPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;

    setState(() => isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await ApiService.createPost(
        userId: user.id,
        categoryId: 1,   // default category
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
                backgroundColor: const Color(0xFFC080D),
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
