import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../utils/app_theme.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  bool _isLoading = false;
  int _currentSuggestionIndex = 0;

  // Shake detection variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _shakeThreshold = 12.0;
  DateTime? _lastShakeTime;
  bool _isShaking = false;

  final List<Map<String, dynamic>> _suggestions = [
    {
      'title': 'Fitur Favorit 💖',
      'content':
          'Aplikasi ini memiliki fitur favorit yang memudahkan Anda menyimpan restoran kesukaan. Cukup tap icon hati pada detail restoran!',
      'icon': Icons.favorite,
      'color': Colors.red,
      'tips':
          'Tip: Gunakan fitur shake to refresh untuk update data favorit Anda',
    },
    {
      'title': 'Pencarian Cerdas 🔍',
      'content':
          'Sistem pencarian mendukung filter berdasarkan nama, lokasi, dan kategori. Filter kategori membantu menemukan jenis makanan yang diinginkan.',
      'icon': Icons.search,
      'color': AppTheme.primaryColor,
      'tips':
          'Tip: Gunakan filter kategori untuk hasil pencarian yang lebih spesifik',
    },
    {
      'title': 'Maps & Navigasi 🗺️',
      'content':
          'Fitur maps menampilkan restoran terdekat dengan rute navigasi real-time. Integrasi dengan Google Maps untuk pengalaman yang optimal.',
      'icon': Icons.map,
      'color': Colors.green,
      'tips':
          'Tip: Shake untuk refresh lokasi dan menemukan restoran baru di sekitar Anda',
    },
    {
      'title': 'Konversi Mata Uang 💱',
      'content':
          'Tools konversi mata uang membantu wisatawan menghitung harga dalam mata uang familiar. Mendukung USD, EUR, JPY, dan IDR.',
      'icon': Icons.currency_exchange,
      'color': Colors.orange,
      'tips': 'Tip: Data kurs diupdate secara real-time dari API Frankfurter',
    },
    {
      'title': 'Review System ⭐',
      'content':
          'Sistem review memungkinkan berbagi pengalaman kuliner. Rating 1-5 bintang dengan komentar detail untuk membantu user lain.',
      'icon': Icons.star,
      'color': Colors.amber,
      'tips':
          'Tip: Review yang detail membantu komunitas menemukan tempat makan terbaik',
    },
    {
      'title': 'Shake to Refresh 📱',
      'content':
          'Fitur inovatif shake detection untuk refresh data. Cukup goyangkan ponsel untuk memperbarui informasi restoran dan lokasi.',
      'icon': Icons.smartphone,
      'color': Colors.purple,
      'tips':
          'Tip: Fitur ini bekerja di semua screen utama untuk kemudahan penggunaan',
    },
  ];

  final List<Map<String, dynamic>> _impressions = [
    {
      'title': 'User Experience 🎨',
      'content':
          'Interface yang clean dan modern dengan navigasi intuitif. Penggunaan warna yang konsisten menciptakan pengalaman visual yang menyenangkan.',
      'icon': Icons.design_services,
      'color': Colors.blue,
    },
    {
      'title': 'Performance ⚡',
      'content':
          'Aplikasi responsif dengan loading time yang optimal. Caching data dan image loading yang efisien untuk pengalaman yang smooth.',
      'icon': Icons.speed,
      'color': Colors.green,
    },
    {
      'title': 'Innovation 🚀',
      'content':
          'Fitur shake detection dan real-time currency converter memberikan nilai tambah yang unik. Integrasi maps yang seamless.',
      'icon': Icons.rocket_launch,
      'color': Colors.orange,
    },
    {
      'title': 'Accessibility ♿',
      'content':
          'Design yang accessible dengan ukuran teks yang readable, kontras warna yang baik, dan navigasi yang mudah untuk semua pengguna.',
      'icon': Icons.accessibility,
      'color': Colors.indigo,
    },
  ];

  @override
  void initState() {
    super.initState();
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
    if (_isShaking) return;

    setState(() {
      _isShaking = true;
    });

    HapticFeedback.heavyImpact();

    // Rotate to next suggestion
    setState(() {
      _currentSuggestionIndex =
          (_currentSuggestionIndex + 1) % _suggestions.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Shake detected! Showing tip ${_currentSuggestionIndex + 1}',
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isShaking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _isShaking ? 'Updating Tips...' : 'Saran & Kesan',
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
                      AnimatedRotation(
                        turns: _isShaking ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: const Icon(
                          Icons.lightbulb,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isShaking
                            ? 'Generating new tips...'
                            : 'Tips & Panduan Aplikasi',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isShaking ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  onPressed: () => _onShakeDetected(),
                  tooltip: 'Next Tip',
                ),
              ],
            ),

            // Shake Instruction
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.rotationZ(_isShaking ? 0.1 : 0),
                      child: const Icon(
                        Icons.smartphone,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shake for Random Tips',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isShaking
                                ? 'Generating tips...'
                                : 'Goyangkan ponsel untuk tips acak',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isShaking)
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
                ),
              ),
            ),

            // Featured Suggestion
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Featured Tip',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
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
                            '${_currentSuggestionIndex + 1}/${_suggestions.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeaturedCard(_suggestions[_currentSuggestionIndex]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // All Suggestions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Semua Saran Fitur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _buildSuggestionCard(
                    _suggestions[index],
                    index == _currentSuggestionIndex,
                  ),
                );
              }, childCount: _suggestions.length),
            ),

            // Impressions Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Kesan Aplikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _buildImpressionCard(_impressions[index]),
                );
              }, childCount: _impressions.length),
            ),

            // Footer
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> suggestion) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [suggestion['color'].withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: suggestion['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    suggestion['icon'],
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              suggestion['content'],
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: suggestion['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: suggestion['color'].withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: suggestion['color'],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion['tips'],
                      style: TextStyle(
                        fontSize: 12,
                        color: suggestion['color'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion, bool isActive) {
    return Card(
      elevation: isActive ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isActive
                ? BorderSide(color: AppTheme.primaryColor, width: 2)
                : BorderSide.none,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: suggestion['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(suggestion['icon'], color: suggestion['color'], size: 20),
        ),
        title: Text(
          suggestion['title'],
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          suggestion['content'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing:
            isActive
                ? const Icon(Icons.star, color: AppTheme.primaryColor)
                : null,
      ),
    );
  }

  Widget _buildImpressionCard(Map<String, dynamic> impression) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: impression['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                impression['icon'],
                color: impression['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    impression['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    impression['content'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
