import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../api_service.dart';

class StudentQAColors {
  static const Color color0 = Color(0xFFC080DD);
  static const Color color1 = Colors.black;
  static const Color color2 = Color(0xFF38263F);
  static const Color color3 = Color(0xFF52425C);
  static const Color color4 = Color(0xFF7A6284);
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
  Set<int> _readAnswers = {};

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

      final qaDataFuture = ApiService.getStudentQAHistory(studentId: user.id);
      final availableCategoriesFuture = ApiService.getCategoriesWithTeachers();
      
      final qaData = await qaDataFuture;
      final availableCategories = await availableCategoriesFuture;
      
      setState(() {
        questions = qaData['questions'] ?? [];
        privateAnswers = qaData['private_answers'] ?? [];
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

  void _markAsRead(int answerId) {
    setState(() {
      _readAnswers.add(answerId);
    });
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getDateGroup(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return 'This Week';
      if (difference.inDays < 30) return 'This Month';
      return 'Earlier';
    } catch (e) {
      return 'Earlier';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.refresh, color: StudentQAColors.white),
            onPressed: fetchData,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: StudentQAColors.color0))
          : Column(
              children: [
                _buildCategoryFilter(),
                Expanded(child: _buildTabContent()),
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
    if (_currentIndex == 1) return SizedBox.shrink();
    
    List<String> categoryOptions = ['all'] + categories.map((c) => c['name'] as String).toList();
    
    return Container(
      height: 55,
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
              margin: EdgeInsets.only(right: 8, top: 8),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? StudentQAColors.color0 : StudentQAColors.color3,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  category == 'all' ? 'All' : category,
                  style: TextStyle(
                    color: StudentQAColors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    final tabs = [
      {'title': 'My Questions', 'icon': Icons.question_answer, 'count': questions.length},
      {'title': 'Private Answers', 'icon': Icons.mail_lock, 'count': privateAnswers.length},
    ];
    
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: StudentQAColors.color2,
            borderRadius: BorderRadius.circular(12),
          ),
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
                      color: isSelected ? StudentQAColors.color0.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          color: isSelected ? StudentQAColors.color0 : StudentQAColors.white70,
                          size: 20,
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tab['title'] as String,
                              style: TextStyle(
                                color: isSelected ? StudentQAColors.white : StudentQAColors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 11,
                              ),
                            ),
                            if ((tab['count'] as int) > 0) ...[
                              SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? StudentQAColors.color0 : StudentQAColors.color3,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${tab['count']}',
                                  style: TextStyle(
                                    color: StudentQAColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
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
            Icon(Icons.question_answer_outlined, size: 64, color: StudentQAColors.white54),
            SizedBox(height: 16),
            Text('No questions yet', style: TextStyle(color: StudentQAColors.white54, fontSize: 18)),
            SizedBox(height: 8),
            Text('Tap the + button to ask your first question', style: TextStyle(color: StudentQAColors.white54, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchData,
      color: StudentQAColors.color0,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: 80),
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
            Icon(Icons.mail_lock_outlined, size: 64, color: StudentQAColors.white54),
            SizedBox(height: 16),
            Text('No private answers yet', style: TextStyle(color: StudentQAColors.white54, fontSize: 18)),
            SizedBox(height: 8),
            Text('Teachers will send private answers to your questions', style: TextStyle(color: StudentQAColors.white54, fontSize: 14)),
          ],
        ),
      );
    }

    final groupedAnswers = <String, List<dynamic>>{};
    for (final answer in privateAnswers) {
      final dateGroup = _getDateGroup(answer['created_at']);
      if (!groupedAnswers.containsKey(dateGroup)) {
        groupedAnswers[dateGroup] = [];
      }
      groupedAnswers[dateGroup]!.add(answer);
    }

    final dateOrder = ['Today', 'Yesterday', 'This Week', 'This Month', 'Earlier'];

    return RefreshIndicator(
      onRefresh: fetchData,
      color: StudentQAColors.color0,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: 80),
        itemCount: dateOrder.where((d) => groupedAnswers.containsKey(d)).length,
        itemBuilder: (context, index) {
          final dateGroup = dateOrder.where((d) => groupedAnswers.containsKey(d)).toList()[index];
          final answers = groupedAnswers[dateGroup]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(dateGroup == 'Today' ? Icons.today : dateGroup == 'Yesterday' ? Icons.history : Icons.calendar_today, color: StudentQAColors.color0, size: 16),
                    SizedBox(width: 8),
                    Text(dateGroup, style: TextStyle(color: StudentQAColors.color0, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(width: 8),
                    Text('(${answers.length})', style: TextStyle(color: StudentQAColors.white54, fontSize: 12)),
                  ],
                ),
              ),
              ...answers.map((answer) => _buildPrivateAnswerCard(answer)).toList(),
              SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudentQAColors.color3,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: StudentQAColors.color0, size: 14),
              SizedBox(width: 6),
              Text(question['category_name'] ?? 'Unknown Category', style: TextStyle(color: StudentQAColors.color0, fontSize: 11, fontWeight: FontWeight.bold)),
              Spacer(),
              Text(_formatTime(question['created_at']), style: TextStyle(color: StudentQAColors.white54, fontSize: 11)),
            ],
          ),
          SizedBox(height: 8),
          Text(question['title'] ?? 'No title', style: TextStyle(color: StudentQAColors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(question['content'] ?? '', style: TextStyle(color: StudentQAColors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.comment_outlined, color: StudentQAColors.white54, size: 12),
              SizedBox(width: 4),
              Text('${question['answer_count'] ?? 0} answers', style: TextStyle(color: StudentQAColors.white54, fontSize: 11)),
              if ((question['accepted_answers'] ?? 0) > 0) ...[
                SizedBox(width: 12),
                Icon(Icons.check_circle, color: Colors.green, size: 12),
                SizedBox(width: 4),
                Text('Answered', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateAnswerCard(dynamic answer) {
    final isRead = _readAnswers.contains(answer['answer_id']);
    
    return GestureDetector(
      onTap: () => _markAsRead(answer['answer_id']),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? StudentQAColors.color3 : StudentQAColors.color2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isRead ? StudentQAColors.color4 : StudentQAColors.color0.withOpacity(0.5), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: StudentQAColors.color0, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text((answer['author'] ?? 'U')[0].toUpperCase(), style: TextStyle(color: StudentQAColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: StudentQAColors.color0, size: 12),
                      SizedBox(width: 4),
                      Text(answer['author'] ?? 'Unknown', style: TextStyle(color: StudentQAColors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text(_formatTime(answer['created_at']), style: TextStyle(color: StudentQAColors.white54, fontSize: 11)),
                    ],
                  ),
                  SizedBox(height: 4),
                  if (answer['category_name'] != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: StudentQAColors.color4, borderRadius: BorderRadius.circular(4)),
                      child: Text(answer['category_name'], style: TextStyle(color: StudentQAColors.white70, fontSize: 10)),
                    ),
                    SizedBox(height: 4),
                  ],
                  Text('Re: ${answer['post_title'] ?? 'Unknown Post'}', style: TextStyle(color: StudentQAColors.color0, fontSize: 11)),
                  SizedBox(height: 6),
                  Text(answer['content'] ?? '', style: TextStyle(color: StudentQAColors.white, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (!isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: StudentQAColors.color0, borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }

  void _showCreateQuestionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateQuestionModal(categories: categories, onQuestionCreated: fetchData),
    );
  }
}

class CreateQuestionModal extends StatefulWidget {
  final List<dynamic> categories;
  final VoidCallback onQuestionCreated;
  
  const CreateQuestionModal({Key? key, required this.categories, required this.onQuestionCreated}) : super(key: key);

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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a question title'), backgroundColor: Colors.red));
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter question details'), backgroundColor: Colors.red));
      return;
    }
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a subject category'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) throw Exception('User not authenticated');

      await ApiService.createPost(userId: user.id, categoryId: selectedCategory['id'], title: _titleController.text, content: _contentController.text);
      widget.onQuestionCreated();
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error creating question: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create question: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(color: StudentQAColors.color2, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ask a Question', style: TextStyle(color: StudentQAColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            if (widget.categories.isNotEmpty) ...[
              Text('Select Subject', style: TextStyle(color: StudentQAColors.white70, fontSize: 14)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: StudentQAColors.color3, borderRadius: BorderRadius.circular(8), border: Border.all(color: StudentQAColors.color4)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: selectedCategory,
                    items: widget.categories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category['name'] ?? 'Unknown', style: TextStyle(color: StudentQAColors.white)));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCategory = value),
                    dropdownColor: StudentQAColors.color3,
                    icon: Icon(Icons.keyboard_arrow_down, color: StudentQAColors.white),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            TextField(controller: _titleController, style: TextStyle(color: StudentQAColors.white), decoration: InputDecoration(labelText: 'Question Title', labelStyle: TextStyle(color: StudentQAColors.white70), filled: true, fillColor: StudentQAColors.color3, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: StudentQAColors.color4)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: StudentQAColors.color0)))),
            SizedBox(height: 16),
            TextField(controller: _contentController, style: TextStyle(color: StudentQAColors.white), maxLines: 4, decoration: InputDecoration(labelText: 'Question Details', labelStyle: TextStyle(color: StudentQAColors.white70), filled: true, fillColor: StudentQAColors.color3, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: StudentQAColors.color4)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: StudentQAColors.color0)))),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitQuestion,
              style: ElevatedButton.styleFrom(backgroundColor: StudentQAColors.color0, padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: isSubmitting
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(StudentQAColors.white)))
                  : Text('Ask Question', style: TextStyle(color: StudentQAColors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

