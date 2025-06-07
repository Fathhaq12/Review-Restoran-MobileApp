import '../models/user.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import '../services/shared_prefs_service.dart';

/// Service controller that provides high-level methods for common app operations
/// Following the pattern from successful mobile apps architecture
class AppController {
  static AppController? _instance;
  static AppController get instance => _instance ??= AppController._internal();

  AppController._internal();

  SharedPrefsService? _prefsService;

  Future<SharedPrefsService> get prefsService async {
    _prefsService ??= await SharedPrefsService.getInstance();
    return _prefsService!;
  }

  // Authentication Methods
  Future<AuthResult> signIn(String username, String password) async {
    try {
      final result = await ApiService.login(username, password);

      if (result['success'] == true) {
        return AuthResult(
          success: true,
          user: result['user'] as User?,
          token: result['token'] as String?,
          message: result['message'] as String?,
        );
      } else {
        return AuthResult(
          success: false,
          error:
              result['message'] as String? ??
              result['error'] as String? ??
              'Login gagal',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Gagal menghubungi server: $e');
    }
  }

  Future<AuthResult> signUp(String name, String email, String password) async {
    try {
      final result = await ApiService.register(name, email, password);

      if (result['success'] == true) {
        return AuthResult(
          success: true,
          user: result['user'] as User?,
          token: result['token'] as String?,
          message: result['message'] as String?,
        );
      } else {
        return AuthResult(
          success: false,
          error:
              result['message'] as String? ??
              result['error'] as String? ??
              'Registrasi gagal',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Gagal menghubungi server: $e');
    }
  }

  Future<bool> signOut() async {
    try {
      await ApiService.logout();
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    final prefs = await prefsService;
    return prefs.getCurrentUser();
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await prefsService;
    return prefs.isLoggedIn();
  }

  // Restaurant Methods
  Future<DataResult<List<Restaurant>>> getRestaurants() async {
    try {
      final restaurants = await ApiService.getRestaurants();
      return DataResult(success: true, data: restaurants);
    } catch (e) {
      return DataResult(
        success: false,
        error: 'Failed to load restaurants: $e',
      );
    }
  }

  Future<DataResult<Restaurant>> getRestaurantDetail(int id) async {
    try {
      final restaurant = await ApiService.getRestaurantById(id);
      if (restaurant != null) {
        return DataResult(success: true, data: restaurant);
      } else {
        return DataResult(success: false, error: 'Restaurant not found');
      }
    } catch (e) {
      return DataResult(success: false, error: 'Failed to load restaurant: $e');
    }
  }

  // Review Methods
  Future<DataResult<List<Review>>> getRestaurantReviews(
    int restaurantId,
  ) async {
    try {
      final reviews = await ApiService.getRestaurantReviews(restaurantId);
      return DataResult(success: true, data: reviews);
    } catch (e) {
      return DataResult(success: false, error: 'Failed to load reviews: $e');
    }
  }

  Future<DataResult<bool>> addReview({
    required int restaurantId,
    required int rating,
    required String comment,
  }) async {
    try {
      final result = await ApiService.createReview(
        restaurantId: restaurantId,
        rating: rating,
        comment: comment,
      );

      return DataResult(
        success: result,
        data: result,
        message:
            result ? 'Review berhasil ditambahkan' : 'Gagal menambahkan review',
      );
    } catch (e) {
      return DataResult(success: false, error: 'Failed to add review: $e');
    }
  }

  // Menu Methods
  Future<DataResult<List<Menu>>> getRestaurantMenu(int restaurantId) async {
    try {
      final menus = await ApiService.getRestaurantMenu(restaurantId);
      return DataResult(success: true, data: menus);
    } catch (e) {
      return DataResult(success: false, error: 'Failed to load menu: $e');
    }
  }

  // User Profile Methods
  Future<DataResult<User>> getUserProfile() async {
    try {
      final user = await ApiService.getUserProfile();
      if (user != null) {
        return DataResult(success: true, data: user);
      } else {
        return DataResult(success: false, error: 'Failed to load user profile');
      }
    } catch (e) {
      return DataResult(
        success: false,
        error: 'Failed to load user profile: $e',
      );
    }
  }

  Future<DataResult<bool>> updateUserProfile({
    required String name,
    required String email,
  }) async {
    try {
      final result = await ApiService.updateUserProfile(
        name: name,
        email: email,
      );

      return DataResult(
        success: result,
        message:
            result ? 'Profile berhasil diupdate' : 'Gagal mengupdate profile',
      );
    } catch (e) {
      return DataResult(success: false, error: 'Failed to update profile: $e');
    }
  }

  // Currency Methods
  Future<DataResult<Map<String, dynamic>>> getCurrencyRates() async {
    try {
      final result = await ApiService.getCurrencyRates();

      if (result != null) {
        return DataResult(success: true, data: result);
      } else {
        return DataResult(
          success: false,
          error: 'Failed to get currency rates',
        );
      }
    } catch (e) {
      return DataResult(
        success: false,
        error: 'Failed to get currency rates: $e',
      );
    }
  }

  // Favorites Methods
  Future<List<String>> getFavoriteRestaurants() async {
    final prefs = await prefsService;
    return prefs.getFavoriteRestaurants();
  }

  Future<bool> addToFavorites(int restaurantId) async {
    final prefs = await prefsService;
    return prefs.addToFavorites(restaurantId);
  }

  Future<bool> removeFromFavorites(int restaurantId) async {
    final prefs = await prefsService;
    return prefs.removeFromFavorites(restaurantId);
  }

  Future<bool> isFavorite(int restaurantId) async {
    final prefs = await prefsService;
    return prefs.isFavorite(restaurantId);
  }

  Future<List<Restaurant>> getFavoriteRestaurantDetails() async {
    try {
      final favoriteIds = await getFavoriteRestaurants();
      if (favoriteIds.isEmpty) return [];

      final result = await getRestaurants();
      if (result.success && result.data != null) {
        return result.data!
            .where(
              (restaurant) => favoriteIds.contains(restaurant.id.toString()),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Error loading favorite restaurant details: $e');
      return [];
    }
  }
}

// Result classes for better type safety and error handling
class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? message;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.message,
    this.error,
  });
}

class DataResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  DataResult({required this.success, this.data, this.message, this.error});
}
