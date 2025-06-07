import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Saran & Kesan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Teknologi dan Pemrograman Mobile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kesan dan Saran Mata Kuliah',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Student Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Informasi Mahasiswa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nama', 'Muhammad Fathahillah Haqqi'),
                    const SizedBox(height: 8),
                    _buildInfoRow('NIM', '123220140'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Program Studi', 'Teknik Informatika'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Course Rating
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Penilaian Mata Kuliah',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRatingRow('Rating Keseluruhan', 4.5, Colors.amber),
                    const SizedBox(height: 12),
                    _buildRatingRow(
                      'Tingkat Kesulitan',
                      5,
                      AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kesan
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Kesan & Pengalaman',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mata kuliah Teknologi dan Pemrograman Mobile sangat menarik dan menantang. Saya sangat menikmati proses pembelajaran Flutter development, mulai dari konsep dasar hingga implementasi fitur-fitur advanced seperti API integration, state management, dan responsive design.\n\nProyek akhir Restaurant Review App memberikan pengalaman hands-on yang sangat berharga dalam mengembangkan aplikasi mobile yang kompleks dengan berbagai fitur seperti user authentication, location services, dan real-time notifications.\n\nPembelajaran tentang best practices dalam mobile development, clean architecture, dan testing juga sangat membantu dalam memahami standar industri pengembangan aplikasi mobile.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Saran
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Saran Perbaikan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Beberapa saran untuk pengembangan mata kuliah ini:\n\n• Menambahkan lebih banyak workshop praktik untuk deployment ke platform store (Google Play Store/App Store)\n\n• Memberikan studi kasus pengembangan aplikasi enterprise dengan complex business logic\n\n• Menambahkan materi tentang performance optimization dan memory management dalam Flutter\n\n• Mengintegrasikan pembelajaran tentang CI/CD pipeline untuk mobile app development\n\n• Menambahkan sesi code review dan best practices dalam tim development',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Thank You Card
            Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_emotions,
                      color: AppTheme.primaryColor,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Terima Kasih',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mata kuliah ini telah memberikan foundation yang kuat dalam mobile development dan membuka peluang karir di bidang teknologi mobile.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(String label, double rating, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              Icons.star,
              size: 20,
              color: index < rating.floor() ? color : color.withOpacity(0.3),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
