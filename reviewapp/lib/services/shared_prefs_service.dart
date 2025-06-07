import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class SharedPrefsService {
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyFavoriteRestaurants = 'favorite_restaurants';

  static SharedPrefsService? _instance;
  static SharedPreferences? _preferences;

  static Future<SharedPrefsService> getInstance() async {
    _instance ??= SharedPrefsService();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Auth Token Methods
  Future<void> setAuthToken(String token) async {
    await _preferences!.setString(_keyAuthToken, token);
  }

  String? getAuthToken() {
    return _preferences!.getString(_keyAuthToken);
  }

  Future<void> removeAuthToken() async {
    await _preferences!.remove(_keyAuthToken);
  }

  // User Session Methods
  Future<void> saveUserSession(User user, String token) async {
    await _preferences!.setString(_keyAuthToken, token);
    await _preferences!.setInt(_keyUserId, user.id);
    await _preferences!.setString(_keyUserName, user.username);
    await _preferences!.setString(_keyUserEmail, user.email);
    await _preferences!.setBool(_keyIsLoggedIn, true);
  }

  User? getCurrentUser() {
    if (!isLoggedIn()) return null;

    final id = _preferences!.getInt(_keyUserId);
    final name = _preferences!.getString(_keyUserName);
    final email = _preferences!.getString(_keyUserEmail);

    if (id != null && name != null && email != null) {
      return User(id: id, username: name, email: email, role: 'user');
    }
    return null;
  }

  bool isLoggedIn() {
    return _preferences!.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> clearUserSession() async {
    await _preferences!.remove(_keyAuthToken);
    await _preferences!.remove(_keyUserId);
    await _preferences!.remove(_keyUserName);
    await _preferences!.remove(_keyUserEmail);
    await _preferences!.setBool(_keyIsLoggedIn, false);
  }

  // User Profile Update
  Future<void> updateUserProfile(User user) async {
    await _preferences!.setString(_keyUserName, user.username);
    await _preferences!.setString(_keyUserEmail, user.email);
  }

  // General Preferences
  Future<void> setString(String key, String value) async {
    await _preferences!.setString(key, value);
  }

  String? getString(String key) {
    return _preferences!.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _preferences!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _preferences!.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _preferences!.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences!.getInt(key);
  }

  Future<void> remove(String key) async {
    await _preferences!.remove(key);
  }

  Future<void> clear() async {
    await _preferences!.clear();
  }

  // Favorites Methods
  Future<List<String>> getFavoriteRestaurants() async {
    return _preferences!.getStringList(_keyFavoriteRestaurants) ?? [];
  }

  Future<bool> addToFavorites(int restaurantId) async {
    final favorites = await getFavoriteRestaurants();
    final restaurantIdStr = restaurantId.toString();

    if (!favorites.contains(restaurantIdStr)) {
      favorites.add(restaurantIdStr);
      await _preferences!.setStringList(_keyFavoriteRestaurants, favorites);
      return true;
    }
    return false;
  }

  Future<bool> removeFromFavorites(int restaurantId) async {
    final favorites = await getFavoriteRestaurants();
    final restaurantIdStr = restaurantId.toString();

    if (favorites.contains(restaurantIdStr)) {
      favorites.remove(restaurantIdStr);
      await _preferences!.setStringList(_keyFavoriteRestaurants, favorites);
      return true;
    }
    return false;
  }

  Future<bool> isFavorite(int restaurantId) async {
    final favorites = await getFavoriteRestaurants();
    return favorites.contains(restaurantId.toString());
  }

  // Legacy static methods for backward compatibility
  static Future<void> saveUser(User user) async {
    final service = await getInstance();
    await service.saveUserSession(user, service.getAuthToken() ?? '');
  }

  static Future<User?> getUser() async {
    final service = await getInstance();
    return service.getCurrentUser();
  }

  static Future<void> saveToken(String token) async {
    final service = await getInstance();
    await service.setAuthToken(token);
  }

  static Future<String?> getToken() async {
    final service = await getInstance();
    return service.getAuthToken();
  }

  static Future<void> clearUserData() async {
    final service = await getInstance();
    await service.clearUserSession();
  }

  static Future<bool> isUserLoggedIn() async {
    final service = await getInstance();
    return service.isLoggedIn();
  }
}
