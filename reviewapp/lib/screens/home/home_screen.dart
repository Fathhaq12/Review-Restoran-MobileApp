import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/app_controller.dart';
import '../../models/restaurant.dart';
import '../../utils/app_theme.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/time_widget.dart';
import '../../widgets/currency_converter.dart';
import '../restaurant/restaurant_detail_screen.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  final AppController _appController = AppController.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  Position? _currentPosition;
  Map<String, dynamic>? _currencyRates;
  bool _hasSearched = false;
  String _userName = '';

  // Shake detection variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _shakeThreshold = 12.0;
  DateTime? _lastShakeTime;
  bool _isShaking = false;

  // Filter state
  String _selectedCategory = 'Semua';
  List<String> _availableCategories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
    _loadCurrencyRates();
    _startShakeDetection();
    _loadUserName();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

    // Calculate shake intensity
    final acceleration = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Check if shake is strong enough and not too frequent
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

    // Show shake feedback
    NotificationService.showCustomMessage(
      "Shake Detected! 📱",
      "Refreshing restaurant data...",
    );

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Wait a moment for user feedback
    await Future.delayed(const Duration(milliseconds: 300));

    // Trigger refresh
    await _loadData();

    setState(() {
      _isShaking = false;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _appController.getRestaurants();
      if (result.success && result.data != null) {
        setState(() {
          _restaurants = result.data!;
          _filteredRestaurants = _restaurants;

          // Extract unique categories
          _availableCategories = ['Semua'];
          final categories =
              _restaurants
                  .map((restaurant) => restaurant.category)
                  .toSet()
                  .toList();
          _availableCategories.addAll(categories);
        });

        // Apply current filters
        _applyFilters();

        // Show success notification
        NotificationService.showCustomMessage(
          "Data Updated! 🔄",
          "Loaded ${_restaurants.length} restaurants successfully",
        );
      }
    } catch (e) {
      print('Error loading restaurants: $e');

      // Show error notification
      NotificationService.showCustomMessage(
        "Connection Error 📡",
        "Failed to load restaurants. Please check your connection.",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRestaurants(String query) {
    setState(() {
      _hasSearched = query.isNotEmpty;
    });
    _applyFilters();
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _hasSearched = _searchController.text.isNotEmpty || category != 'Semua';
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Restaurant> filtered = _restaurants;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered =
          filtered.where((restaurant) {
            final name = restaurant.name.toLowerCase();
            final location = restaurant.location.toLowerCase();
            final category = restaurant.category.toLowerCase();

            return name.contains(query) ||
                location.contains(query) ||
                category.contains(query);
          }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'Semua') {
      filtered =
          filtered.where((restaurant) {
            return restaurant.category == _selectedCategory;
          }).toList();
    }

    setState(() {
      _filteredRestaurants = filtered;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'Semua';
      _hasSearched = false;
      _filteredRestaurants = _restaurants;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadCurrencyRates() async {
    try {
      final result = await _appController.getCurrencyRates();
      if (result.success && result.data != null) {
        setState(() {
          _currencyRates = result.data!;
        });
      }
    } catch (e) {
      print('Error loading currency rates: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = await _appController.getCurrentUser();
      if (user != null) {
        setState(() {
          _userName = user.username;
        });
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  void _showTimeConverter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TimeWidget(),
    );
  }

  void _showCurrencyConverter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencyConverter(rates: _currencyRates),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return '🌅'; // sunrise
    } else if (hour >= 11 && hour < 15) {
      return '☀️'; // sun
    } else if (hour >= 15 && hour < 18) {
      return '🌤️'; // partly sunny
    } else {
      return '🌙'; // moon
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // App Bar with Greeting
              SliverAppBar(
                expandedHeight: 250,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _isShaking ? 'Refreshing...' : 'Restaurant Review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Greeting Section
                        if (_userName.isNotEmpty) ...[
                          Text(
                            '${_getGreeting()}, ${_userName}! ${_getGreetingIcon()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                        ],

                        AnimatedRotation(
                          turns: _isShaking ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: const Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isShaking
                              ? 'Detecting shake...'
                              : 'Temukan restoran terbaik untuk Anda',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isShaking) ...[
                          const SizedBox(height: 8),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.white),
                    onPressed: _showTimeConverter,
                    tooltip: 'Konversi Waktu',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.currency_exchange,
                      color: Colors.white,
                    ),
                    onPressed: _showCurrencyConverter,
                    tooltip: 'Konversi Mata Uang',
                  ),
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _isShaking ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: const Icon(Icons.refresh, color: Colors.white),
                    ),
                    onPressed: _isLoading ? null : _loadData,
                    tooltip: 'Refresh Manual',
                  ),
                ],
              ),

              // Personal Welcome Card - Simplified
              if (_userName.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, ${_userName}! ${_getGreetingIcon()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Siap menjelajahi kuliner hari ini?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('HH:mm').format(DateTime.now()),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Search Bar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cari Restoran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Cari nama restoran, jenis masakan, atau lokasi...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.primaryColor,
                          ),
                          suffixIcon:
                              (_searchController.text.isNotEmpty ||
                                      _selectedCategory != 'Semua')
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearAllFilters,
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: _filterRestaurants,
                      ),
                    ],
                  ),
                ),
              ),

              // Category Filter
              if (_availableCategories.length > 1)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.filter_list,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Filter Kategori',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (_selectedCategory != 'Semua') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_filteredRestaurants.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableCategories.length,
                            itemBuilder: (context, index) {
                              final category = _availableCategories[index];
                              final isSelected = category == _selectedCategory;

                              return Padding(
                                padding: EdgeInsets.only(
                                  right:
                                      index < _availableCategories.length - 1
                                          ? 8
                                          : 0,
                                ),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    _filterByCategory(category);
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: AppTheme.primaryColor
                                      .withOpacity(0.2),
                                  checkmarkColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary
                                                .withOpacity(0.3),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

              // Time and Currency Quick Access
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: _showTimeConverter,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppTheme.primaryColor,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Konversi Waktu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(DateTime.now()),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: _showCurrencyConverter,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.currency_exchange,
                                    color: AppTheme.primaryColor,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Konversi Mata Uang',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'IDR • USD • EUR • JPY',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Results or Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _hasSearched
                              ? _buildFilteredTitle()
                              : 'Restoran Populer',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (_hasSearched && _filteredRestaurants.isNotEmpty)
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: const Text('Lihat Semua'),
                        ),
                    ],
                  ),
                ),
              ),

              // Restaurant List
              if (_isLoading || _isShaking)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isShaking
                                ? 'Shake detected! Refreshing...'
                                : 'Loading restaurants...',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_filteredRestaurants.isEmpty && _hasSearched)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 80,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada hasil ditemukan',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coba dengan kata kunci lain: "${_searchController.text}"',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_restaurants.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_outlined,
                            size: 80,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada restoran',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final restaurant = _filteredRestaurants[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
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
                            // Ensure backward compatibility
                            'address': restaurant.location,
                            'description': restaurant.category,
                            'imageUrl': restaurant.image,
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => RestaurantDetailScreen(
                                    restaurant: restaurantMap,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  }, childCount: _filteredRestaurants.length),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildFilteredTitle() {
    List<String> filters = [];

    if (_searchController.text.isNotEmpty) {
      filters.add('pencarian');
    }

    if (_selectedCategory != 'Semua') {
      filters.add('kategori "$_selectedCategory"');
    }

    String filterText = filters.join(' & ');
    return 'Hasil ${filterText.isNotEmpty ? filterText : 'filter'} (${_filteredRestaurants.length})';
  }
}
