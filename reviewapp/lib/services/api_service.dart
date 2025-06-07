import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/menu.dart';
import 'shared_prefs_service.dart';

class ApiService {
  static const String baseUrl =
      'https://be-restoran-1061342868557.us-central1.run.app/api';
  static const String fallbackUrl = 'http://localhost:5000/api';
  static const String currencyApiUrl = 'https://api.frankfurter.dev/v1/latest';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  // Auth methods following the pattern from the GitHub repo
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      // Try deployed API first
      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse('$baseUrl/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'username': username, 'password': password}),
            )
            .timeout(Duration(seconds: 10));
      } catch (e) {
        // If deployed API fails, try local fallback
        print('Deployed API failed, trying fallback URL: $e');
        response = await http.post(
          Uri.parse('$fallbackUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        );
      }
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isNotEmpty) {
          try {
            final data = jsonDecode(responseBody);
            final token = data['accessToken'] ?? data['token'];
            if (token != null) {
              // Save token
              await SharedPrefsService.saveToken(token);

              // For now, create a basic user object since backend doesn't return user data in login
              // We'll fetch user data separately if needed
              final basicUser = User(
                id: 0, // Will be updated when fetching profile
                username: username, // Use username as temporary name
                email: '', // Will be updated when fetching profile
                role: 'user',
              );

              await SharedPrefsService.saveUser(basicUser);

              return {
                'success': true,
                'token': token,
                'user': basicUser,
                'data': data,
              };
            } else {
              // Token is null
              return {
                'success': false,
                'error': 'No access token received from server',
                'data': data,
              };
            }
          } catch (parseError) {
            print('JSON parse error: $parseError');
            return {
              'success': false,
              'error': 'Invalid response format',
              'details': parseError.toString(),
            };
          }
        }
      }

      // Handle error response
      final responseBody = response.body;
      Map<String, dynamic> errorData = {};

      if (responseBody.isNotEmpty) {
        try {
          errorData = jsonDecode(responseBody);
        } catch (e) {
          errorData = {'message': responseBody};
        }
      }

      return {
        'success': false,
        'data': errorData,
        'message': errorData['message'] ?? 'Login gagal',
      };
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'error':
            'Gagal menghubungi server. Pastikan koneksi internet Anda stabil.',
        'details': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Try deployed API first
      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse('$baseUrl/auth/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': name,
                'email': email,
                'password': password,
              }),
            )
            .timeout(Duration(seconds: 10));
      } catch (e) {
        // If deployed API fails, try local fallback
        print('Deployed API failed, trying fallback URL: $e');
        response = await http.post(
          Uri.parse('$fallbackUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': name,
            'email': email,
            'password': password,
          }),
        );
      }
      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      final responseBody = response.body;
      Map<String, dynamic> data = {};

      if (responseBody.isNotEmpty) {
        try {
          data = jsonDecode(responseBody);
        } catch (e) {
          data = {'message': responseBody};
        }
      }

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'message':
            data['message'] ??
            (response.statusCode == 200 || response.statusCode == 201
                ? 'Registrasi berhasil'
                : 'Registrasi gagal'),
      };
    } catch (e) {
      print('Register error: $e');
      return {
        'success': false,
        'error':
            'Gagal menghubungi server. Pastikan koneksi internet Anda stabil.',
        'details': e.toString(),
      };
    }
  }

  static Future<bool> logout() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/logout'),
        headers: headers,
      );

      // Clear local data regardless of server response
      await SharedPrefsService.clearUserData();

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      // Clear local data even if server request fails
      await SharedPrefsService.clearUserData();
      return false;
    }
  }

  // Restaurant methods with proper model usage
  static Future<List<Restaurant>> getRestaurants() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> restaurantList = jsonDecode(response.body);
        return restaurantList.map((json) => Restaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  static Future<Restaurant?> getRestaurantById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final restaurantData = jsonDecode(response.body);
        return Restaurant.fromJson(restaurantData);
      }
      return null;
    } catch (e) {
      print('Error fetching restaurant: $e');
      return null;
    }
  }

  // Review methods
  static Future<List<Review>> getRestaurantReviews(int restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/restaurant/$restaurantId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> reviewList = jsonDecode(response.body);
        return reviewList.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  static Future<bool> createReview({
    required int restaurantId,
    required int rating,
    required String comment,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: headers,
        body: jsonEncode({
          'restaurantId': restaurantId,
          'rating': rating,
          'comment': comment,
          // Remove userId - it will be extracted from the token by backend
        }),
      );

      print('Create review response status: ${response.statusCode}');
      print('Create review response body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating review: $e');
      return false;
    }
  }

  // Menu methods - Since backend doesn't have menu by restaurant endpoint, return empty list
  static Future<List<Menu>> getRestaurantMenu(int restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/menus'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> menuList = jsonDecode(response.body);
        // Filter menus by restaurantId on client side
        return menuList
            .map((json) => Menu.fromJson(json))
            .where((menu) => menu.restaurantId == restaurantId)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching menu: $e');
      // Return empty list instead of throwing error
      return [];
    }
  }

  // User profile methods
  static Future<User?> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<bool> updateUserProfile({
    required String name,
    required String email,
  }) async {
    try {
      final headers = await _getHeaders();

      // Get current user to get the ID
      final currentUser = await SharedPrefsService.getUser();
      if (currentUser == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/users/${currentUser.id}'),
        headers: headers,
        body: jsonEncode({'username': name, 'email': email}),
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Currency conversion
  static Future<Map<String, dynamic>?> getCurrencyRates() async {
    try {
      // Request rates from IDR to other currencies
      final response = await http.get(
        Uri.parse('$currencyApiUrl?from=IDR&to=USD,EUR,JPY'),
      );

      print('Currency API response status: ${response.statusCode}');
      print('Currency API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Frankfurter API structure: {"amount":1,"base":"IDR","date":"2024-xx-xx","rates":{"USD":0.000065,"EUR":0.000059,"JPY":0.0097}}
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching currency rates: $e');
      return null;
    }
  }

  // Helper methods
  static Future<Map<String, String>> _getHeaders() async {
    final token = await SharedPrefsService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
