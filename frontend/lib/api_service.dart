import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ------------------------------
  // Base URL
  // ------------------------------
  static const String baseUrl = 'http://localhost:8001';

  // ------------------------------
  // GET ALL POSTS
  // ------------------------------
  static Future<List<dynamic>> getPosts() async {
    final response = await http.get(Uri.parse('$baseUrl/get_posts.php'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  // ------------------------------
  // GET ANSWERS FOR A POST (with privacy filtering)
  // ------------------------------
  static Future<List<dynamic>> getAnswers(int postId, {int? currentUserId}) async {
    String url = '$baseUrl/get_answers.php?post_id=$postId';
    if (currentUserId != null) {
      url += '&current_user_id=$currentUserId';
    }
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load answers');
    }
  }

  // ------------------------------
  // CREATE NEW POST
  // ------------------------------
  static Future<Map<String, dynamic>> createPost({
    required int userId,
    required int categoryId,
    required String title,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_post.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'category_id': categoryId,
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create post');
    }
  }

  // ------------------------------
  // CREATE NEW ANSWER (with privacy controls)
  // ------------------------------
  static Future<Map<String, dynamic>> createAnswer({
    required int userId,
    required int postId,
    required String content,
    String visibility = 'public',
    int? targetStudentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_answer.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'post_id': postId,
        'content': content,
        'visibility': visibility,
        'target_student_id': targetStudentId,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create answer');
    }
  }



  // ------------------------------
  // GET ALL CATEGORIES
  // ------------------------------
static Future<List<dynamic>> getCategories() async {
  final response = await http.get(Uri.parse('$baseUrl/get_categories.php'));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load categories');
  }
}

  // ------------------------------
  // CREATE NEW CATEGORY
  // ------------------------------
static Future<Map<String, dynamic>> createCategory({
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_category.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create category');
    }
  }

  // ------------------------------
  // DELETE CATEGORY
  // ------------------------------
  static Future<Map<String, dynamic>> deleteCategory({
    required int categoryId,
    required String authToken,
  }) async {
    print('API Service - deleteCategory called');
    print('Category ID: $categoryId');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/delete_category.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'category_id': categoryId,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }
  // ------------------------------
  // VOTE ON POST OR ANSWER
  // ------------------------------
  static Future<Map<String, dynamic>> vote({
    required int userId,
    required String targetType, // 'post' or 'answer'
    required int targetId,
    required int value, // 1 = upvote, -1 = downvote
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vote.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'target_type': targetType,
        'target_id': targetId,
        'value': value,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to vote');
    }
  }

  // ------------------------------
  // USER LOGIN
  // ------------------------------
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to login');
    }
  }

  // ------------------------------
  // USER REGISTRATION
  // ------------------------------
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? bio,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'bio': bio,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to register');
    }
  }

  // ------------------------------
  // USER LOGOUT
  // ------------------------------
  static Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout.php'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to logout');
    }
  }

  // ------------------------------
  // GET CURRENT USER
  // ------------------------------
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_user.php'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get current user');
    }
  }

  // ------------------------------
  // UPDATE USER PROFILE
  // ------------------------------
  static Future<Map<String, dynamic>> updateUser({
    required String authToken,
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? currentPassword,
    String? newPassword,
  }) async {
    print('API Service - updateUser called');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/update_user.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'full_name': fullName,
        'bio': bio,
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // ------------------------------
  // ADMIN: GET ALL USERS (Admin only)
  // ------------------------------
  static Future<Map<String, dynamic>> getAllUsers({
    required String authToken,
  }) async {
    print('API Service - getAllUsers called (Admin)');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    final response = await http.get(
      Uri.parse('$baseUrl/get_all_users.php'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get all users: ${response.body}');
    }
  }

  // ------------------------------
  // ADMIN: DELETE USER (Admin only)
  // ------------------------------
  static Future<Map<String, dynamic>> deleteUser({
    required String authToken,
    required int userId,
  }) async {
    print('API Service - deleteUser called (Admin)');
    print('User ID: $userId');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/delete_user.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'user_id': userId,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  // ------------------------------
  // ADMIN: DELETE POST (Admin only)
  // ------------------------------
  static Future<Map<String, dynamic>> deletePost({
    required String authToken,
    required int postId,
  }) async {
    print('API Service - deletePost called (Admin)');
    print('Post ID: $postId');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/delete_post.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'post_id': postId,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  // ------------------------------
  // ADMIN: ASSIGN ROLE (Admin only)
  // ------------------------------
  static Future<Map<String, dynamic>> assignUserRole({
    required String authToken,
    required int userId,
    required String userType, // 'student', 'teacher', 'admin'
  }) async {
    print('API Service - assignUserRole called (Admin)');
    print('User ID: $userId');
    print('User Type: $userType');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/assign_teacher_role.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'user_id': userId,
        'user_type': userType,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to assign user role: ${response.body}');
    }
  }

  // ------------------------------
  // GET CATEGORIES WITH TEACHERS (QA System)
  // ------------------------------
  static Future<List<dynamic>> getCategoriesWithTeachers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_categories_with_teachers.php'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories with teachers');
    }
  }

  // ------------------------------
  // GET STUDENT QA HISTORY (QA System)
  // ------------------------------
  static Future<Map<String, dynamic>> getStudentQAHistory({
    required int studentId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_student_qa_history.php?student_id=$studentId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load student QA history');
    }
  }

  // ------------------------------
  // GET TEACHER QUESTIONS (QA System)
  // ------------------------------
  static Future<Map<String, dynamic>> getTeacherQuestions({
    required int teacherId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_teacher_questions.php?teacher_id=$teacherId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load teacher questions');
    }
  }

  // ------------------------------
  // ASSIGN TEACHER TO CATEGORY (Admin only)
  // ------------------------------
  static Future<Map<String, dynamic>> assignTeacherCategory({
    required String authToken,
    required int categoryId,
    required int teacherId,
  }) async {
    print('API Service - assignTeacherCategory called (Admin)');
    print('Category ID: $categoryId');
    print('Teacher ID: $teacherId');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/assign_teacher_category.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'category_id': categoryId,
        'teacher_id': teacherId,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to assign teacher to category: ${response.body}');
    }
  }

  // ------------------------------
  // GET CATEGORY-TEACHER ASSIGNMENTS (Admin only)
  // ------------------------------
  static Future<Map<String, dynamic>> getCategoryTeacherAssignments({
    required String authToken,
  }) async {
    print('API Service - getCategoryTeacherAssignments called (Admin)');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    final response = await http.get(
      Uri.parse('$baseUrl/get_category_teacher_assignments.php'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get category-teacher assignments: ${response.body}');
    }
  }

  // ------------------------------
  // REMOVE TEACHER FROM CATEGORY (Admin only)
  // ------------------------------
  static Future<Map<String, dynamic>> removeTeacherFromCategory({
    required String authToken,
    required int assignmentId,
  }) async {
    print('API Service - removeTeacherFromCategory called (Admin)');
    print('Assignment ID: $assignmentId');
    print('Auth Token: ${authToken.substring(0, 20)}...');
    
    // First, we need to create this endpoint or use a generic delete approach
    // For now, we'll use the existing delete endpoint structure if available
    final response = await http.post(
      Uri.parse('$baseUrl/remove_teacher_category.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'assignment_id': assignmentId,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to remove teacher from category: ${response.body}');
    }
  }
}
