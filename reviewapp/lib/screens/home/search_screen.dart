import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/app_controller.dart';
import '../../utils/app_theme.dart';
import '../restaurant/restaurant_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyRestaurants = [];
  bool _isLoading = true;
  bool _showMap = true;
  bool _isLoadingRoute = false;
  final AppController _appController = AppController.instance;
  final MapController _mapController = MapController();
  List<LatLng> _polylinePoints = [];
  Map<String, dynamic>? _selectedRestaurant;

  // Shake detection variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _shakeThreshold = 12.0;
  DateTime? _lastShakeTime;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

    // Show shake feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shake detected! Refreshing location...'),
        backgroundColor: AppTheme.primaryColor,
        duration: Duration(seconds: 1),
      ),
    );

    // Haptic feedback
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 300));

    // Refresh location and restaurants
    await _getCurrentLocation();

    setState(() {
      _isShaking = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _generateDummyRestaurants();
    } catch (e) {
      print('Error getting location: $e');
      _showLocationError();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateDummyRestaurants() {
    if (_currentPosition == null) return;

    final math.Random random = math.Random();
    final List<String> restaurantNames = [
      'Warung Padang Sederhana',
      'Sate Kambing Pak Haji',
      'Gudeg Yu Djum',
      'Bakso Solo Pak Kumis',
      'Nasi Pecel Bu Tini',
      'Ayam Geprek Bensu',
      'Mie Ayam Tumini',
      'Soto Betawi Haji Mamat',
      'Gado-gado Jakarta',
      'Rendang Minang Asli',
      'Martabak Har Bang Adul',
      'Es Cendol Elizabeth',
      'Ikan Bakar Cianjur',
      'Pecel Lele Lela',
      'Rawon Setan Pak Pangat',
    ];

    final List<String> categories = [
      'Makanan Padang',
      'Sate & Grilled',
      'Makanan Jawa',
      'Bakso & Mie',
      'Makanan Tradisional',
      'Ayam & Unggas',
      'Martabak & Dessert',
      'Seafood',
      'Minuman & Snack',
    ];

    _nearbyRestaurants.clear();

    for (int i = 0; i < restaurantNames.length; i++) {
      // Generate random coordinates within 5km radius
      double randomLat =
          _currentPosition!.latitude +
          (random.nextDouble() - 0.5) * 0.05; // ~2.5km radius
      double randomLng =
          _currentPosition!.longitude + (random.nextDouble() - 0.5) * 0.05;

      double distance =
          Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            randomLat,
            randomLng,
          ) /
          1000; // Convert to km

      _nearbyRestaurants.add({
        'id': i + 1,
        'name': restaurantNames[i],
        'category': categories[random.nextInt(categories.length)],
        'location':
            'Jl. ${_generateStreetName()} No. ${random.nextInt(100) + 1}',
        'latitude': randomLat,
        'longitude': randomLng,
        'distance': distance,
        'rating': (random.nextDouble() * 2 + 3).toStringAsFixed(1),
        'image': 'https://picsum.photos/200/150?random=$i',
        'isOpen': random.nextBool(),
        'priceRange': ['\$', '\$\$', '\$\$\$'][random.nextInt(3)],
      });
    }

    // Sort by distance
    _nearbyRestaurants.sort((a, b) => a['distance'].compareTo(b['distance']));
  }

  String _generateStreetName() {
    final List<String> streets = [
      'Sudirman',
      'Thamrin',
      'Gatot Subroto',
      'Kuningan',
      'Menteng',
      'Kemang',
      'Pondok Indah',
      'Senayan',
      'Blok M',
      'Kelapa Gading',
      'Pancoran',
      'Tebet',
      'Cikini',
      'Salemba',
      'Matraman',
    ];
    return streets[math.Random().nextInt(streets.length)];
  }

  Future<void> _getDirections(Map<String, dynamic> restaurant) async {
    if (_currentPosition == null) return;

    setState(() {
      _selectedRestaurant = restaurant;
      _polylinePoints.clear();
      _isLoadingRoute = true;
    });

    try {
      LatLng start = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      LatLng end = LatLng(restaurant['latitude'], restaurant['longitude']);

      // Try to get real route from OSRM
      List<LatLng> routePoints = await _getRealRoute(start, end);

      setState(() {
        _polylinePoints = routePoints;
        _isLoadingRoute = false;
      });

      // Center map to show both points using move method
      _centerMapOnRoute(start, end);
    } catch (e) {
      print('Error getting directions: $e');
      // Fallback to simple route if API fails
      _getSimpleRoute(restaurant);
    }
  }

  void _centerMapOnRoute(LatLng start, LatLng end) {
    // Calculate center point and zoom level
    double centerLat = (start.latitude + end.latitude) / 2;
    double centerLng = (start.longitude + end.longitude) / 2;

    // Calculate distance to determine appropriate zoom level
    double distance = math.sqrt(
      math.pow(end.latitude - start.latitude, 2) +
          math.pow(end.longitude - start.longitude, 2),
    );

    // Determine zoom level based on distance
    double zoom = 13.0;
    if (distance > 0.1) {
      zoom = 10.0;
    } else if (distance > 0.05) {
      zoom = 11.0;
    } else if (distance > 0.02) {
      zoom = 12.0;
    }

    // Move map to center point
    _mapController.move(LatLng(centerLat, centerLng), zoom);
  }

  Future<List<LatLng>> _getRealRoute(LatLng start, LatLng end) async {
    try {
      // Using OSRM (Free, no API key needed)
      return await _getOSRMRoute(start, end);
    } catch (e) {
      print('Error getting real route: $e');
      // Fallback to simple curved route
      return _generateSimpleRoute(start, end);
    }
  }

  Future<List<LatLng>> _getOSRMRoute(LatLng start, LatLng end) async {
    final String url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;

        return coordinates.map<LatLng>((coord) {
          return LatLng(coord[1].toDouble(), coord[0].toDouble());
        }).toList();
      }
    }

    throw Exception('Failed to get route from OSRM');
  }

  void _getSimpleRoute(Map<String, dynamic> restaurant) async {
    LatLng start = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    LatLng end = LatLng(restaurant['latitude'], restaurant['longitude']);

    List<LatLng> points = _generateSimpleRoute(start, end);

    setState(() {
      _polylinePoints = points;
      _isLoadingRoute = false;
    });
  }

  List<LatLng> _generateSimpleRoute(LatLng start, LatLng end) {
    List<LatLng> points = [];

    // Add waypoints for a more realistic route
    double latDiff = end.latitude - start.latitude;
    double lngDiff = end.longitude - start.longitude;

    for (int i = 0; i <= 20; i++) {
      double ratio = i / 20.0;

      // Add some curve to make it look more like a real route
      double curveFactor = math.sin(ratio * math.pi) * 0.001;

      double lat = start.latitude + (latDiff * ratio) + curveFactor;
      double lng = start.longitude + (lngDiff * ratio) + curveFactor;

      points.add(LatLng(lat, lng));
    }

    return points;
  }

  Future<void> _openExternalMaps(double lat, double lng, String name) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name';

    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka aplikasi maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Layanan Lokasi Dinonaktifkan'),
            content: const Text(
              'Mohon aktifkan layanan lokasi untuk melihat restoran terdekat.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Izin Lokasi Diperlukan'),
            content: const Text(
              'Aplikasi memerlukan izin lokasi untuk menampilkan restoran terdekat.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nanti'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Geolocator.openAppSettings();
                },
                child: const Text('Pengaturan'),
              ),
            ],
          ),
    );
  }

  void _showLocationError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendapatkan lokasi. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with toggle
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
                          Icons.map,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isShaking
                              ? 'Refreshing Location...'
                              : 'Restoran Terdekat',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // Toggle View Button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showMap = !_showMap;
                          });
                        },
                        icon: Icon(
                          _showMap ? Icons.list : Icons.map,
                          color: AppTheme.primaryColor,
                        ),
                        tooltip: _showMap ? 'Tampilan List' : 'Tampilan Peta',
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        icon: AnimatedRotation(
                          turns: _isShaking ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: const Icon(Icons.refresh),
                        ),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),

                  // Shake instruction
                  if (!_isLoading && _currentPosition != null) ...[
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
                            _isShaking ? 'Refreshing...' : 'Shake to refresh',
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

                  if (_currentPosition != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                            'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (_isShaking)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
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
                                  ? 'Shake detected! Refreshing location...'
                                  : 'Mencari lokasi Anda...',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                      : _currentPosition == null
                      ? _buildLocationError()
                      : _showMap
                      ? _buildMapView()
                      : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) return const SizedBox();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            initialZoom: 13.0,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            // Map tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.reviewapp',
            ),

            // Polyline for directions
            if (_polylinePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polylinePoints,
                    color: AppTheme.primaryColor,
                    strokeWidth: 4.0,
                  ),
                ],
              ),

            // Markers
            MarkerLayer(
              markers: [
                // User location marker
                Marker(
                  point: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Restaurant markers
                ..._nearbyRestaurants.map((restaurant) {
                  bool isSelected =
                      _selectedRestaurant?['id'] == restaurant['id'];
                  return Marker(
                    point: LatLng(
                      restaurant['latitude'],
                      restaurant['longitude'],
                    ),
                    child: GestureDetector(
                      onTap: () => _showRestaurantInfo(restaurant),
                      child: Container(
                        width: isSelected ? 50 : 40,
                        height: isSelected ? 50 : 40,
                        decoration: BoxDecoration(
                          color:
                              restaurant['isOpen']
                                  ? AppTheme.primaryColor
                                  : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 4 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: isSelected ? 25 : 20,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Loading indicator for route
        if (_isLoadingRoute)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Mencari rute...',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

        // Clear directions button
        if (_polylinePoints.isNotEmpty && !_isLoadingRoute)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _polylinePoints.clear();
                  _selectedRestaurant = null;
                });
                // Reset map to user location
                _mapController.move(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  13.0,
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.clear, color: AppTheme.primaryColor),
            ),
          ),

        // Route info panel
        if (_polylinePoints.isNotEmpty && _selectedRestaurant != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rute ke ${_selectedRestaurant!['name']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_selectedRestaurant!['distance'].toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        () => _openExternalMaps(
                          _selectedRestaurant!['latitude'],
                          _selectedRestaurant!['longitude'],
                          _selectedRestaurant!['name'],
                        ),
                    icon: const Icon(
                      Icons.open_in_new,
                      color: AppTheme.primaryColor,
                    ),
                    tooltip: 'Buka di Google Maps',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showRestaurantInfo(Map<String, dynamic> restaurant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: restaurant['isOpen'] ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        restaurant['isOpen'] ? 'Buka' : 'Tutup',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant['category'],
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text('${restaurant['distance'].toStringAsFixed(1)} km'),
                    const SizedBox(width: 16),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(restaurant['rating']),
                    const SizedBox(width: 16),
                    Text(
                      restaurant['priceRange'],
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoadingRoute
                                ? null
                                : () {
                                  Navigator.pop(context);
                                  _getDirections(restaurant);
                                },
                        icon:
                            _isLoadingRoute
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.directions),
                        label: Text(
                          _isLoadingRoute ? 'Loading...' : 'Petunjuk Arah',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => RestaurantDetailScreen(
                                    restaurant: restaurant,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info),
                        label: const Text('Detail'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openExternalMaps(
                        restaurant['latitude'],
                        restaurant['longitude'],
                        restaurant['name'],
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Buka di Google Maps'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildListView() {
    return _buildRestaurantList();
  }

  Widget _buildLocationError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Lokasi Tidak Tersedia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mohon aktifkan layanan lokasi untuk melihat restoran terdekat',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantList() {
    if (_nearbyRestaurants.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada restoran ditemukan di sekitar Anda',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _nearbyRestaurants[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          RestaurantDetailScreen(restaurant: restaurant),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Restaurant Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.secondaryColor,
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Restaurant Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    restaurant['isOpen']
                                        ? Colors.green
                                        : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                restaurant['isOpen'] ? 'Buka' : 'Tutup',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant['category'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant['distance'].toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              restaurant['rating'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              restaurant['priceRange'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Direction Button
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => _showRestaurantInfo(restaurant),
                        icon: const Icon(
                          Icons.map,
                          color: AppTheme.primaryColor,
                        ),
                        tooltip: 'Lihat di Peta',
                      ),
                      IconButton(
                        onPressed:
                            () => _openExternalMaps(
                              restaurant['latitude'],
                              restaurant['longitude'],
                              restaurant['name'],
                            ),
                        icon: const Icon(
                          Icons.directions,
                          color: AppTheme.secondaryColor,
                        ),
                        tooltip: 'Google Maps',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
