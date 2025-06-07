import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/app_controller.dart';
import '../../models/restaurant.dart';
import '../../utils/app_theme.dart';
import '../../widgets/restaurant_card.dart';
import '../restaurant/restaurant_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Restaurant> _favoriteRestaurants = [];
  bool _isLoading = true;
  final AppController _appController = AppController.instance;

  // Shake detection variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _shakeThreshold = 12.0;
  DateTime? _lastShakeTime;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _startShakeDetection();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      _detectShake(event);
    });
  }

  void _detectShake(AccelerometerEvent event) {
    final now = DateTime.now();

    final acceleration = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (acceleration > _shakeThreshold && !_isShaking) {
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!).inMilliseconds > 1000) {
        _lastShakeTime = now;
        _onShakeDetected();
      }
    }
  }

  void _onShakeDetected() async {
    if (_isShaking || _isLoading) return;

    setState(() {
      _isShaking = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shake detected! Refreshing favorites...'),
        backgroundColor: AppTheme.primaryColor,
        duration: Duration(seconds: 1),
      ),
    );

    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 300));
    await _loadFavorites();

    setState(() {
      _isShaking = false;
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load favorite restaurants using AppController
      final favoriteRestaurants =
          await _appController.getFavoriteRestaurantDetails();
      setState(() {
        _favoriteRestaurants = favoriteRestaurants;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(int restaurantId) async {
    final success = await _appController.removeFromFavorites(restaurantId);

    if (success) {
      setState(() {
        _favoriteRestaurants.removeWhere(
          (restaurant) => restaurant.id == restaurantId,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restoran dihapus dari favorit'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  void _showRemoveDialog(Restaurant restaurant) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus dari Favorit'),
            content: Text('Hapus ${restaurant.name} dari daftar favorit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _removeFavorite(restaurant.id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedRotation(
                        turns: _isShaking ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: const Icon(
                          Icons.favorite,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isShaking
                              ? 'Refreshing Favorites...'
                              : 'Restoran Favorit',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (_favoriteRestaurants.isNotEmpty && !_isShaking)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_favoriteRestaurants.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (_isShaking)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),

                  if (_favoriteRestaurants.isNotEmpty || _isShaking) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            transform: Matrix4.rotationZ(_isShaking ? 0.1 : 0),
                            child: const Icon(
                              Icons.smartphone,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isShaking
                                ? 'Refreshing...'
                                : 'Shake to refresh favorites',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFavorites,
                color: AppTheme.primaryColor,
                child:
                    _isLoading || _isShaking
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isShaking
                                    ? 'Shake detected! Refreshing favorites...'
                                    : 'Loading favorites...',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                        : _favoriteRestaurants.isEmpty
                        ? _buildEmptyState()
                        : _buildFavoritesList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        const Icon(
          Icons.favorite_border,
          size: 120,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(height: 24),
        const Text(
          'Belum Ada Favorit',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mulai jelajahi restoran dan tambahkan ke favorit untuk melihatnya di sini',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to search or home
            DefaultTabController.of(context).animateTo(0);
          },
          icon: const Icon(Icons.search),
          label: const Text('Jelajahi Restoran'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _favoriteRestaurants[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: Key(restaurant.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            confirmDismiss: (direction) async {
              _showRemoveDialog(restaurant);
              return false; // Don't auto dismiss, let dialog handle it
            },
            child: RestaurantCard(
              restaurant: restaurant,
              onTap: () {
                // Convert Restaurant to Map for RestaurantDetailScreen
                final restaurantMap = {
                  'id': restaurant.id,
                  'name': restaurant.name,
                  'location': restaurant.location,
                  'category': restaurant.category,
                  'image': restaurant.image,
                  // Ensure all required fields are present
                  'address': restaurant.location,
                  'description': restaurant.category,
                  'imageUrl': restaurant.image,
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            RestaurantDetailScreen(restaurant: restaurantMap),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
