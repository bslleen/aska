import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../api_service.dart';

// Color palette (matching the existing app theme)
class TeacherQAColors {
  static const Color color0 = Color(0xFFC080DD); // Orange/pink accent
  static const Color color1 = Colors.black; // Black background
  static const Color color2 = Color(0xFF38263F); // Dark purple
  static const Color color3 = Color(0xFF52425C); // Medium purple
  static const Color color4 = Color(0xFF7A6284); // Light purple
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
}

class TeacherQADashboard extends StatefulWidget {
  const TeacherQADashboard({Key? key}) : super(key: key);

  @override
  State<TeacherQADashboard> createState() => _TeacherQADashboardState();
}

class _TeacherQADashboardState extends State<TeacherQADashboard> {
  List<dynamic> questions = [];
  List<dynamic> assignedCategories = [];
  Map<String, dynamic>? teacherData;
  bool isLoading = true;
  String selectedCategory = 'all';

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

      // Fetch teacher's questions and assigned categories
      final teacherDataResponse = await ApiService.getTeacherQuestions(teacherId: user.id);
      
      setState(() {
        teacherData = teacherDataResponse;
        questions = teacherDataResponse['questions'] ?? [];
        assignedCategories = teacherDataResponse['assigned_categories'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching teacher QA data: $e');
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
      backgroundColor: TeacherQAColors.color1,
      appBar: AppBar(
        backgroundColor: TeacherQAColors.color1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teacher Dashboard',
              style: TextStyle(
                color: TeacherQAColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Questions from Your Subjects',
              style: TextStyle(
                color: TeacherQAColors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TeacherQAColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: TeacherQAColors.color0))
          : Column(
              children: [
                // Stats cards
                _buildStatsCards(),
                
                // Category filter
                _buildCategoryFilter(),
                
                // Questions list
                Expanded(
                  child: _buildQuestionsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCards() {
    final stats = teacherData?['stats'] ?? {};
    final totalQuestions = questions.length;
    final categoriesCount = assignedCategories.length;
    
    return Container(
      margin: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Questions',
              totalQuestions.toString(),
              Icons.question_answer,
              TeacherQAColors.color0,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Subjects',
              categoriesCount.toString(),
              Icons.school,
              TeacherQAColors.color4,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Answers',
              stats['total_answers']?.toString() ?? '0',
              Icons.forum,
              TeacherQAColors.color2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeacherQAColors.color2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: TeacherQAColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: TeacherQAColors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    List<String> categoryOptions = ['all'] + assignedCategories.map((c) => c['name'] as String).toList();
    
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryOptions.length,
        itemBuilder: (context, index) {
          final category = categoryOptions[index];
          final isSelected = (category == 'all' && selectedCategory == 'all') || 
                            (category != 'all' && assignedCategories.any((c) => c['name'] == category && c['id'].toString() == selectedCategory));
          
          return GestureDetector(
            onTap: () {
              setState(() {
                if (category == 'all') {
                  selectedCategory = 'all';
                } else {
                  final catData = assignedCategories.firstWhere((c) => c['name'] == category);
                  selectedCategory = catData['id'].toString();
                }
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 8, top: 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? TeacherQAColors.color0 : TeacherQAColors.color3,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category == 'all' ? 'All Subjects' : category,
                style: TextStyle(
                  color: TeacherQAColors.white,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
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
              Icons.inbox_outlined,
              size: 64,
              color: TeacherQAColors.white54,
            ),
            SizedBox(height: 16),
            Text(
              selectedCategory == 'all' 
                  ? 'No questions yet' 
                  : 'No questions for this subject',
              style: TextStyle(
                color: TeacherQAColors.white54,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Students will ask questions in your assigned subjects',
              style: TextStyle(
                color: TeacherQAColors.white54,
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

  Widget _buildQuestionCard(dynamic question) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeacherQAColors.color3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (question['accepted_answers'] ?? 0) > 0 
              ? Colors.green 
              : TeacherQAColors.color4,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: TeacherQAColors.color0, size: 16),
              SizedBox(width: 8),
              Text(
                question['student_name'] ?? 'Unknown Student',
                style: TextStyle(
                  color: TeacherQAColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                _formatDate(question['created_at']),
                style: TextStyle(
                  color: TeacherQAColors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.school, color: TeacherQAColors.color0, size: 16),
              SizedBox(width: 8),
              Text(
                question['category_name'] ?? 'Unknown Category',
                style: TextStyle(
                  color: TeacherQAColors.color0,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if ((question['accepted_answers'] ?? 0) > 0) ...[
                SizedBox(width: 16),
                Icon(Icons.check_circle, color: Colors.green, size: 16),
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
          SizedBox(height: 12),
          Text(
            question['title'] ?? 'No title',
            style: TextStyle(
              color: TeacherQAColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            question['content'] ?? '',
            style: TextStyle(
              color: TeacherQAColors.white70,
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.message, color: TeacherQAColors.white54, size: 14),
              SizedBox(width: 4),
              Text(
                '${question['answer_count'] ?? 0} answers',
                style: TextStyle(
                  color: TeacherQAColors.white54,
                  fontSize: 12,
                ),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () => _showAnswerDialog(question),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherQAColors.color0,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Answer',
                  style: TextStyle(
                    color: TeacherQAColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(dynamic question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnswerQuestionScreen(
          question: question,
          onAnswerCreated: fetchData,
        ),
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

// Answer Question Screen
class AnswerQuestionScreen extends StatefulWidget {
  final dynamic question;
  final VoidCallback onAnswerCreated;
  
  const AnswerQuestionScreen({
    Key? key,
    required this.question,
    required this.onAnswerCreated,
  }) : super(key: key);

  @override
  State<AnswerQuestionScreen> createState() => _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends State<AnswerQuestionScreen> {
  final _answerController = TextEditingController();
  String selectedVisibility = 'public';
  bool isSubmitting = false;

  void submitAnswer() async {
    if (_answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an answer'),
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

      final answerData = {
        'user_id': user.id,
        'post_id': widget.question['post_id'],
        'content': _answerController.text,
        'visibility': selectedVisibility,
      };

      // For private answers, include target student
      if (selectedVisibility == 'private') {
        answerData['target_student_id'] = widget.question['user_id']; // Original question author
      }

      await ApiService.createAnswer(
        userId: user.id,
        postId: widget.question['post_id'],
        content: _answerController.text,
        visibility: selectedVisibility,
        targetStudentId: selectedVisibility == 'private' ? widget.question['user_id'] : null,
      );

      widget.onAnswerCreated();
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error creating answer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create answer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherQAColors.color1,
      appBar: AppBar(
        backgroundColor: TeacherQAColors.color1,
        title: Text(
          'Answer Question',
          style: TextStyle(
            color: TeacherQAColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TeacherQAColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question details
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TeacherQAColors.color2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TeacherQAColors.color4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: TeacherQAColors.color0, size: 16),
                      SizedBox(width: 8),
                      Text(
                        widget.question['student_name'] ?? 'Unknown Student',
                        style: TextStyle(
                          color: TeacherQAColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.school, color: TeacherQAColors.color0, size: 16),
                      SizedBox(width: 8),
                      Text(
                        widget.question['category_name'] ?? 'Unknown Category',
                        style: TextStyle(
                          color: TeacherQAColors.color0,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    widget.question['title'] ?? 'No title',
                    style: TextStyle(
                      color: TeacherQAColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.question['content'] ?? '',
                    style: TextStyle(
                      color: TeacherQAColors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Answer input
            Text(
              'Your Answer',
              style: TextStyle(
                color: TeacherQAColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _answerController,
              style: TextStyle(color: TeacherQAColors.white),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                hintStyle: TextStyle(color: TeacherQAColors.white54),
                filled: true,
                fillColor: TeacherQAColors.color3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: TeacherQAColors.color4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: TeacherQAColors.color0),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Privacy settings
            Text(
              'Privacy Settings',
              style: TextStyle(
                color: TeacherQAColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: TeacherQAColors.color2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TeacherQAColors.color4),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'public',
                    groupValue: selectedVisibility,
                    onChanged: (value) {
                      setState(() {
                        selectedVisibility = value!;
                      });
                    },
                    title: Text(
                      'Public Answer',
                      style: TextStyle(color: TeacherQAColors.white),
                    ),
                    subtitle: Text(
                      'Visible to all students',
                      style: TextStyle(color: TeacherQAColors.white70, fontSize: 12),
                    ),
                    activeColor: TeacherQAColors.color0,
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  Divider(color: TeacherQAColors.color4, height: 1),
                  RadioListTile<String>(
                    value: 'private',
                    groupValue: selectedVisibility,
                    onChanged: (value) {
                      setState(() {
                        selectedVisibility = value!;
                      });
                    },
                    title: Text(
                      'Private Answer',
                      style: TextStyle(color: TeacherQAColors.white),
                    ),
                    subtitle: Text(
                      'Only visible to the asking student',
                      style: TextStyle(color: TeacherQAColors.white70, fontSize: 12),
                    ),
                    activeColor: TeacherQAColors.color0,
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherQAColors.color0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(TeacherQAColors.white),
                        ),
                      )
                    : Text(
                        'Submit Answer',
                        style: TextStyle(
                          color: TeacherQAColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
