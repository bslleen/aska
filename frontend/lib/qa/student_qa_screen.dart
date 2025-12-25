import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../api_service.dart';

// Color palette (matching the existing app theme)
class StudentQAColors {
  static const Color color0 = Color(0xFFC080DD); // Orange/pink accent
  static const Color color1 = Colors.black; // Black background
  static const Color color2 = Color(0xFF38263F); // Dark purple
  static const Color color3 = Color(0xFF52425C); // Medium purple
  static const Color color4 = Color(0xFF7A6284); // Light purple
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
}

class StudentQAScreen extends StatefulWidget {
  const StudentQAScreen({Key? key}) : super(key: key);

  @override
  State<StudentQAScreen> createState() => _StudentQAScreenState();
}

class _StudentQAScreenState extends State<StudentQAScreen> {
  List<dynamic> questions = [];
  List<dynamic> privateAnswers = [];
  List<dynamic> categories = [];
  bool isLoading = true;
  String selectedCategory = 'all';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      // Fetch student's Q&A history and all available categories concurrently
      final qaDataFuture = ApiService.getStudentQAHistory(studentId: user.id);
      final availableCategoriesFuture = ApiService.getCategoriesWithTeachers();
      
      final qaData = await qaDataFuture;
      final availableCategories = await availableCategoriesFuture;
      
      setState(() {
        questions = qaData['questions'] ?? [];
        privateAnswers = qaData['private_answers'] ?? [];
        // Use all available categories for question creation, not just used ones
        categories = availableCategories;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching student QA data: $e');
      setState(() => isLoading = false);
    }
  }

  List<dynamic> getFilteredQuestions() {
    if (selectedCategory == 'all') return questions;
    return questions.where((q) => q['category_id'].toString() == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      backgroundColor: StudentQAColors.color1,
      appBar: AppBar(
        backgroundColor: StudentQAColors.color1,
        title: Text(
          'My Questions & Answers',
          style: TextStyle(
            color: StudentQAColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: StudentQAColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: StudentQAColors.color0),
            onPressed: () => _showCreateQuestionDialog(),
            tooltip: 'Ask a Question',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: StudentQAColors.color0))
          : Column(
              children: [
                // Category filter tabs
                _buildCategoryFilter(),
                
                // Content based on selected tab
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateQuestionDialog(),
        backgroundColor: StudentQAColors.color0,
        child: Icon(Icons.add, color: StudentQAColors.white),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    List<String> categoryOptions = ['all'] + categories.map((c) => c['name'] as String).toList();
    
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryOptions.length,
        itemBuilder: (context, index) {
          final category = categoryOptions[index];
          final isSelected = (category == 'all' && selectedCategory == 'all') || 
                            (category != 'all' && categories.any((c) => c['name'] == category && c['id'].toString() == selectedCategory));
          
          return GestureDetector(
            onTap: () {
              setState(() {
                if (category == 'all') {
                  selectedCategory = 'all';
                } else {
                  final catData = categories.firstWhere((c) => c['name'] == category);
                  selectedCategory = catData['id'].toString();
                }
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 8, top: 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? StudentQAColors.color0 : StudentQAColors.color3,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category == 'all' ? 'All' : category,
                style: TextStyle(
                  color: StudentQAColors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    final tabs = ['My Questions', 'Private Answers'];
    
    return Column(
      children: [
        // Tab bar
        Container(
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == _currentIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? StudentQAColors.color0 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? StudentQAColors.white : StudentQAColors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Tab content
        Expanded(
          child: _currentIndex == 0 ? _buildQuestionsList() : _buildPrivateAnswersList(),
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    final filteredQuestions = getFilteredQuestions();
    
    if (filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: StudentQAColors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'No questions yet',
              style: TextStyle(
                color: StudentQAColors.white54,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to ask your first question',
              style: TextStyle(
                color: StudentQAColors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchData,
      child: ListView.builder(
        itemCount: filteredQuestions.length,
        itemBuilder: (context, index) {
          final question = filteredQuestions[index];
          return _buildQuestionCard(question);
        },
      ),
    );
  }

  Widget _buildPrivateAnswersList() {
    if (privateAnswers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: StudentQAColors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'No private answers yet',
              style: TextStyle(
                color: StudentQAColors.white54,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Teachers will send private answers to your questions',
              style: TextStyle(
                color: StudentQAColors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchData,
      child: ListView.builder(
        itemCount: privateAnswers.length,
        itemBuilder: (context, index) {
          final answer = privateAnswers[index];
          return _buildPrivateAnswerCard(answer);
        },
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudentQAColors.color3,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: StudentQAColors.color0, size: 16),
              SizedBox(width: 8),
              Text(
                question['category_name'] ?? 'Unknown Category',
                style: TextStyle(
                  color: StudentQAColors.color0,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                _formatDate(question['created_at']),
                style: TextStyle(
                  color: StudentQAColors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            question['title'] ?? 'No title',
            style: TextStyle(
              color: StudentQAColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            question['content'] ?? '',
            style: TextStyle(
              color: StudentQAColors.white70,
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.message, color: StudentQAColors.white54, size: 14),
              SizedBox(width: 4),
              Text(
                '${question['answer_count'] ?? 0} answers',
                style: TextStyle(
                  color: StudentQAColors.white54,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 16),
              if ((question['accepted_answers'] ?? 0) > 0) ...[
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  'Answered',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateAnswerCard(dynamic answer) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudentQAColors.color2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudentQAColors.color0, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: StudentQAColors.color0, size: 16),
              SizedBox(width: 8),
              Text(
                'Private Answer',
                style: TextStyle(
                  color: StudentQAColors.color0,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                _formatDate(answer['created_at']),
                style: TextStyle(
                  color: StudentQAColors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            answer['post_title'] ?? 'Unknown Post',
            style: TextStyle(
              color: StudentQAColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'From: ${answer['author'] ?? 'Unknown'}',
            style: TextStyle(
              color: StudentQAColors.white70,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          Text(
            answer['content'] ?? '',
            style: TextStyle(
              color: StudentQAColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateQuestionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateQuestionModal(
        categories: categories,
        onQuestionCreated: fetchData,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// Create Question Modal
class CreateQuestionModal extends StatefulWidget {
  final List<dynamic> categories;
  final VoidCallback onQuestionCreated;
  
  const CreateQuestionModal({
    Key? key,
    required this.categories,
    required this.onQuestionCreated,
  }) : super(key: key);

  @override
  State<CreateQuestionModal> createState() => _CreateQuestionModalState();
}

class _CreateQuestionModalState extends State<CreateQuestionModal> {
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

  void submitQuestion() async {
    // Validate each field individually to provide specific error messages
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a question title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter question details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a subject category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (widget.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No categories available. Please contact support.'),
          backgroundColor: Colors.red,
        ),
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

      widget.onQuestionCreated();
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error creating question: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create question: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: StudentQAColors.color2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask a Question',
              style: TextStyle(
                color: StudentQAColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            // Category selector
            if (widget.categories.isNotEmpty) ...[
              Text(
                'Select Subject',
                style: TextStyle(
                  color: StudentQAColors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: StudentQAColors.color3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StudentQAColors.color4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: selectedCategory,
                    items: widget.categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category['name'] ?? 'Unknown',
                          style: TextStyle(color: StudentQAColors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    dropdownColor: StudentQAColors.color3,
                    icon: Icon(Icons.keyboard_arrow_down, color: StudentQAColors.white),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Title field
            TextField(
              controller: _titleController,
              style: TextStyle(color: StudentQAColors.white),
              decoration: InputDecoration(
                labelText: 'Question Title',
                labelStyle: TextStyle(color: StudentQAColors.white70),
                filled: true,
                fillColor: StudentQAColors.color3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: StudentQAColors.color4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: StudentQAColors.color0),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Content field
            TextField(
              controller: _contentController,
              style: TextStyle(color: StudentQAColors.white),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Question Details',
                labelStyle: TextStyle(color: StudentQAColors.white70),
                filled: true,
                fillColor: StudentQAColors.color3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: StudentQAColors.color4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: StudentQAColors.color0),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Submit button
            ElevatedButton(
              onPressed: isSubmitting ? null : submitQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: StudentQAColors.color0,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(StudentQAColors.white),
                      ),
                    )
                  : Text(
                      'Ask Question',
                      style: TextStyle(
                        color: StudentQAColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
