import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/app_controller.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../other/feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AppController _appController = AppController.instance;
  String _userName = '';
  String _userEmail = '';
  File? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _appController.getCurrentUser();
      if (user != null) {
        setState(() {
          _userName = user.username;
          _userEmail = user.email;
        });
      }

      // Load profile image path if exists
      final prefs = await _appController.prefsService;
      final imagePath = prefs.getString('profile_image_path');
      if (imagePath != null && File(imagePath).existsSync()) {
        setState(() {
          _profileImage = File(imagePath);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // Save image path to preferences
      try {
        final prefs = await _appController.prefsService;
        await prefs.setString('profile_image_path', pickedFile.path);
      } catch (e) {
        print('Error saving image path: $e');
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _appController.signOut();
      if (!success) {
        print('Logout failed, but continuing with local logout');
      }
    } catch (e) {
      print('Logout error: $e');
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _logout();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Image
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                _profileImage != null
                                    ? Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      color: Colors.white,
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // User Info
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu Items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.edit,
                      title: 'Edit Profil',
                      subtitle: 'Ubah informasi profil Anda',
                      onTap: () {
                        // Navigate to edit profile
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur edit profil akan segera hadir',
                            ),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.feedback,
                      title: 'Saran & Kesan',
                      subtitle: 'Mata kuliah Teknologi dan Pemrograman Mobile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FeedbackScreen(),
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: 'Tentang Aplikasi',
                      subtitle: 'Informasi tentang Restaurant Review',
                      onTap: () {
                        _showAboutDialog();
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Bantuan',
                      subtitle: 'Panduan penggunaan aplikasi',
                      onTap: () {
                        _showHelpDialog();
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.notifications,
                      title: 'Notifikasi',
                      subtitle: 'Kelola pengaturan notifikasi aplikasi',
                      onTap: () {
                        // Show notification settings
                        _showNotificationSettings();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _showLogoutDialog,
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(Icons.logout),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tentang Restaurant Review'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version: 0.5.4'),
                SizedBox(height: 8),
                Text('Aplikasi review restoran dengan fitur:'),
                SizedBox(height: 8),
                Text('• Pencarian restoran'),
                Text('• Review dan rating'),
                Text('• Konversi mata uang'),
                Text('• Konversi waktu'),
                Text('• Lokasi GPS'),
                Text('• Shake to refresh'),
                Text('• Smart notifications'),
                SizedBox(height: 8),
                Text(
                  'Dibuat untuk mata kuliah Teknologi dan Pemrograman Mobile',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bantuan'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cara menggunakan aplikasi:'),
                SizedBox(height: 8),
                Text('1. Login dengan akun Anda'),
                Text('2. Jelajahi restoran di halaman beranda'),
                Text('3. Gunakan fitur pencarian untuk menemukan restoran'),
                Text('4. Baca review dan berikan rating'),
                Text('5. Tambahkan restoran ke favorit'),
                Text('6. Gunakan konversi mata uang dan waktu'),
                SizedBox(height: 8),
                Text('Tips: Goyangkan ponsel untuk refresh halaman!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Pengaturan Notifikasi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${NotificationService.isEnabled ? "Aktif" : "Nonaktif"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        NotificationService.isEnabled
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Notifikasi sistem setiap 2 menit untuk:'),
                const SizedBox(height: 8),
                const Text('• Reminder untuk review restoran'),
                const Text('• Tips pencarian kuliner'),
                const Text('• Update fitur aplikasi'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (NotificationService.isEnabled) {
                            await NotificationService.showCustomMessage(
                              "Test Notification! 🔔",
                              "Notifikasi sistem berfungsi dengan baik",
                            );
                          } else {
                            await NotificationService.showPermissionDialog(
                              context,
                            );
                          }
                        },
                        child: Text(
                          NotificationService.isEnabled
                              ? 'Test Notifikasi'
                              : 'Aktifkan Notifikasi',
                        ),
                      ),
                    ),
                  ],
                ),
                if (!NotificationService.isEnabled) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Aktifkan notifikasi untuk mendapatkan tips kuliner dan update terbaru!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
