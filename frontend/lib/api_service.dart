import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ------------------------------
  // Base URL
  // ------------------------------
  static const String baseUrl = 'http://localhost:8000';

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
  // GET ANSWERS FOR A POST
  // ------------------------------
  static Future<List<dynamic>> getAnswers(int postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_answers.php?post_id=$postId'),
    );
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
  // CREATE NEW ANSWER
  // ------------------------------
  static Future<Map<String, dynamic>> createAnswer({
    required int userId,
    required int postId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_answer.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'post_id': postId,
        'content': content,
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
}