import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';

class TimeWidget extends StatefulWidget {
  const TimeWidget({super.key});

  @override
  State<TimeWidget> createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  late DateTime _currentTime;

  final Map<String, int> _timeZones = {
    'WIB': 7, // Western Indonesia Time (UTC+7)
    'WITA': 8, // Central Indonesia Time (UTC+8)
    'WIT': 9, // Eastern Indonesia Time (UTC+9)
    'London': 0, // GMT (UTC+0)
    'US (EST)': -5, // Eastern Standard Time (UTC-5)
    'Japan': 9, // Japan Standard Time (UTC+9)
  };

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Update time every second
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        _startTimer();
      }
    });
  }

  DateTime _getTimeInTimeZone(int offsetHours) {
    final utc = _currentTime.toUtc();
    return utc.add(Duration(hours: offsetHours));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Konversi Waktu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Time zones list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  _timeZones.entries.map((entry) {
                    final timeZoneName = entry.key;
                    final offsetHours = entry.value;
                    final timeInZone = _getTimeInTimeZone(offsetHours);
                    final isCurrentLocation =
                        timeZoneName == 'WIB'; // Assuming user is in WIB

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isCurrentLocation
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            isCurrentLocation
                                ? Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                )
                                : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  isCurrentLocation
                                      ? AppTheme.primaryColor
                                      : AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _getTimeZoneIcon(timeZoneName),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeZoneName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isCurrentLocation
                                            ? AppTheme.primaryColor
                                            : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  _getTimeZoneDescription(timeZoneName),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('HH:mm:ss').format(timeInZone),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isCurrentLocation
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy').format(timeInZone),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Footer info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Waktu diperbarui secara otomatis setiap detik',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTimeZoneIcon(String timeZone) {
    switch (timeZone) {
      case 'WIB':
      case 'WITA':
      case 'WIT':
        return Icons.home;
      case 'London':
        return Icons.location_city;
      case 'US (EST)':
        return Icons.location_city;
      case 'Japan':
        return Icons.location_city;
      default:
        return Icons.access_time;
    }
  }

  String _getTimeZoneDescription(String timeZone) {
    switch (timeZone) {
      case 'WIB':
        return 'Waktu Indonesia Barat';
      case 'WITA':
        return 'Waktu Indonesia Tengah';
      case 'WIT':
        return 'Waktu Indonesia Timur';
      case 'London':
        return 'Greenwich Mean Time';
      case 'US (EST)':
        return 'Eastern Standard Time';
      case 'Japan':
        return 'Japan Standard Time';
      default:
        return '';
    }
  }
}
