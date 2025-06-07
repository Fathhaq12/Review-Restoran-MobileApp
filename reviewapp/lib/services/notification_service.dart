import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static Timer? _periodicTimer;
  static bool _isInitialized = false;
  static BuildContext? _context;
  static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  static bool _notificationsEnabled = false;

  // Restaurant-themed notification messages
  static final List<String> _notificationMessages = [
    "🍽️ Jangan lupa untuk review restoran favoritmu!",
    "⭐ Bagikan pengalaman kulinermu dengan rating dan review",
    "🍕 Ada restoran baru yang menanti untuk dijelajahi",
    "☕ Waktunya mencari tempat makan yang menarik",
    "🍜 Cek menu dan harga terbaru di restoran sekitarmu",
    "🥘 Temukan hidden gem kuliner di aplikasi ini",
    "🍰 Simpan restoran favorit untuk referensi nanti",
    "🍱 Bandingkan harga dengan konverter mata uang kami",
    "🥗 Jangan lewatkan promo dan update restoran terbaru",
    "🍔 Shake your phone untuk refresh dan cari restoran baru!",
  ];

  static final List<String> _notificationTitles = [
    "Restaurant Review",
    "Kuliner Time!",
    "Food Explorer",
    "Makan Yuuk!",
    "Restoran Hunter",
  ];

  static Future<void> initialize() async {
    if (_isInitialized) return;

    print('Initializing Notification Service...');

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('Notification Service initialized successfully');
  }

  static Future<bool> requestNotificationPermissions() async {
    try {
      // Request notification permission
      PermissionStatus permission = await Permission.notification.request();

      if (permission.isGranted) {
        _notificationsEnabled = true;

        // For Android 13+, also request POST_NOTIFICATIONS permission
        if (await Permission.notification.isGranted) {
          // Additional setup for local notifications
          await _flutterLocalNotificationsPlugin!
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();

          await _flutterLocalNotificationsPlugin!
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true);
        }

        print('Notification permissions granted');
        return true;
      } else {
        _notificationsEnabled = false;
        print('Notification permissions denied');
        return false;
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
      _notificationsEnabled = false;
      return false;
    }
  }

  static Future<bool> checkNotificationPermissions() async {
    try {
      PermissionStatus permission = await Permission.notification.status;
      _notificationsEnabled = permission.isGranted;
      return _notificationsEnabled;
    } catch (e) {
      print('Error checking notification permissions: $e');
      _notificationsEnabled = false;
      return false;
    }
  }

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<void> startPeriodicNotifications() async {
    if (_periodicTimer?.isActive == true) {
      print('Periodic notifications already running');
      return;
    }

    // Check permissions first
    bool hasPermission = await checkNotificationPermissions();
    if (!hasPermission) {
      print('No notification permissions, cannot start periodic notifications');
      return;
    }

    print('Starting periodic notifications every 2 minutes...');

    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _showSystemNotification();
    });

    // Show first notification after 10 seconds
    Timer(const Duration(seconds: 10), () {
      _showSystemNotification();
    });
  }

  static void stopPeriodicNotifications() {
    print('Stopping periodic notifications...');
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  static Future<void> _showSystemNotification() async {
    if (!_notificationsEnabled || _flutterLocalNotificationsPlugin == null) {
      print('Notifications not enabled or plugin not initialized');
      return;
    }

    try {
      final random = Random();
      final title =
          _notificationTitles[random.nextInt(_notificationTitles.length)];
      final message =
          _notificationMessages[random.nextInt(_notificationMessages.length)];

      print('Showing system notification: $title - $message');

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Generate unique notification ID
      final notificationId = random.nextInt(1000000);

      // Android notification details
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'restaurant_review_channel',
            'Restaurant Review Notifications',
            channelDescription: 'Notifications for restaurant review app',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@drawable/ic_notification',
            color: Color(0xFF4CAF50),
            enableVibration: true,
            playSound: true,
          );

      // iOS notification details
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin!.show(
        notificationId,
        title,
        message,
        notificationDetails,
        payload: 'restaurant_review_notification',
      );

      print('System notification sent successfully');
    } catch (e) {
      print('Error showing system notification: $e');
    }
  }

  static Future<void> showCustomMessage(String title, String message) async {
    if (!_notificationsEnabled || _flutterLocalNotificationsPlugin == null) {
      print('Notifications not enabled, showing fallback message');
      // Fallback to in-app notification if system notifications are disabled
      if (_context != null && _context!.mounted) {
        _showCustomNotification(_context!, title, message);
      }
      return;
    }

    try {
      HapticFeedback.mediumImpact();

      final random = Random();
      final notificationId = random.nextInt(1000000);

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'restaurant_review_instant',
            'Instant Notifications',
            channelDescription: 'Instant notifications for restaurant actions',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: Color(0xFF4CAF50),
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin!.show(
        notificationId,
        title,
        message,
        notificationDetails,
        payload: 'custom_message',
      );
    } catch (e) {
      print('Error showing custom notification: $e');
      // Fallback to in-app notification
      if (_context != null && _context!.mounted) {
        _showCustomNotification(_context!, title, message);
      }
    }
  }

  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');

    // Handle notification tap - you can navigate to specific screens here
    if (_context != null && _context!.mounted) {
      // Example: Navigate to home screen or specific feature
      // You can add navigation logic here based on the payload
    }
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Izin Notifikasi'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aplikasi Restaurant Review ingin mengirim notifikasi untuk:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text('• Reminder untuk review restoran'),
              Text('• Tips pencarian kuliner'),
              Text('• Update fitur terbaru'),
              Text('• Konfirmasi aksi berhasil'),
              SizedBox(height: 12),
              Text(
                'Notifikasi akan muncul setiap 2 menit dengan tips berguna tentang kuliner.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Nanti Saja'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Izinkan'),
              onPressed: () async {
                Navigator.of(context).pop();
                bool granted = await requestNotificationPermissions();

                if (granted) {
                  showCustomMessage(
                    "Notifikasi Aktif! 🔔",
                    "Anda akan menerima tips kuliner setiap 2 menit",
                  );
                  startPeriodicNotifications();
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Izin notifikasi ditolak. Anda dapat mengaktifkannya nanti di pengaturan.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Fallback in-app notification for when system notifications are disabled
  static void _showCustomNotification(
    BuildContext context,
    String title,
    String message,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: _NotificationWidget(
                title: title,
                message: message,
                onDismiss: () {
                  overlayEntry.remove();
                },
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Timer(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static void dispose() {
    stopPeriodicNotifications();
    _context = null;
    _isInitialized = false;
  }

  // Getter for notification status
  static bool get isEnabled => _notificationsEnabled;
}

// Fallback widget for in-app notifications
class _NotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          onPanUpdate: (details) {
            if (details.delta.dy < -5) {
              _dismiss();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
