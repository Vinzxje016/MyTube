import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // Title
            const Text(
              'Cá Nhân',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryLight, width: 2),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop&q=80',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alexandre Nguyen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'alex.nguyen@example.com',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Thành viên VIP • Hết hạn 12/2026',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Music Stats Bento
            Row(
              children: [
                _buildStatCard('148', 'Giờ nghe', Icons.headphones_rounded, AppTheme.primary),
                const SizedBox(width: 12),
                _buildStatCard('1,420', 'Bài hát', Icons.music_note_rounded, AppTheme.accent),
                const SizedBox(width: 12),
                _buildStatCard('84', 'Nghệ sĩ', Icons.people_alt_rounded, AppTheme.cyan),
              ],
            ),

            const SizedBox(height: 22),

            // Premium Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(70),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'GÓI PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Âm thanh Lossless 24-bit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nghe nhạc không quảng cáo, tải bài hát chất lượng cao không giới hạn.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {},
                    child: const Text('Chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings Section
            const Text(
              'Cài Đặt Ứng Dụng',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Icons.equalizer_rounded,
              title: 'Bộ chỉnh âm (Equalizer)',
              subtitle: 'Bass Boost, Âm thanh vòm 3D',
              trailing: 'Chuẩn Studio',
            ),
            _buildSettingTile(
              icon: Icons.high_quality_rounded,
              title: 'Chất lượng truyền phát',
              subtitle: 'WiFi & Mạng di động',
              trailing: 'Rất cao (320kbps)',
            ),
            _buildSettingTile(
              icon: Icons.download_done_rounded,
              title: 'Tải xuống ngoại tuyến',
              subtitle: 'Lưu trữ trên thẻ nhớ hoặc bộ nhớ trong',
              trailing: '2.4 GB',
            ),
            _buildSettingTile(
              icon: Icons.timer_outlined,
              title: 'Hẹn giờ ngủ',
              subtitle: 'Tự động tắt nhạc sau thời gian định sẵn',
              trailing: 'Tắt',
            ),
            _buildSettingTile(
              icon: Icons.dark_mode_rounded,
              title: 'Giao diện ứng dụng',
              subtitle: 'Chế độ tối Dark OLED',
              trailing: 'Bật',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailing,
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 12.5),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
            ],
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
